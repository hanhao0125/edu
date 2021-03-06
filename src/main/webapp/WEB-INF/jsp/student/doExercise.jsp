<%@ page pageEncoding="UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <%@include file="../static.jsp" %>
</head>
<body>
<%@include file="../navigation.jsp" %>
<div id="app" class="container">
    <br>
    <h1>本次练习共{{problemsLen}}道题</h1>
    <br>
    <h4>进度:</h4>
    <i-progress :percent="(globalIndex+1)*(100/problemsLen)" status="active" :hide-info="true"></i-progress>
    <br>
    <br>
    <hr>
    <p>{{globalIndex+1}}.{{currentProblem.title}}</p>
    <br>
    <div v-if="currentProblem.type === 1">
        <!-- 选择题 -->
        <Radio-group v-model="answer" vertical>
            <div v-for="(choose,index) in currentProblem.description.split('\n')">
                <Radio :label="index | formatChoose" style="font-size: large;">
                    <span>{{index | formatChoose}} {{choose}}</span>
                </Radio>
            </div>
        </Radio-group>
    </div>
    <div v-else-if="currentProblem.type === 2">
        <!-- 填空 -->
        <i-input v-model="answer" type="textarea" :rows="4" placeholder="参考答案" size="large"
        ></i-input>

    </div>
    <div v-else-if="currentProblem.type === 3">
        <!-- 判断 -->
        <Radio-group v-model="answer">
            <Radio label="对">
            </Radio>
            <Radio label="错">
            </Radio>
        </Radio-group>
    </div>
    <div v-else-if="currentProblem.type === 4">
        <!--  简答 -->
        <i-input v-model="answer" type="textarea" :rows="4" placeholder="参考答案" size="large"
        ></i-input>
    </div>
    <div v-else>
        <!--  编程 -->
    </div>
    <br>
    <Row>
        <i-col>
            <div v-if="globalIndex+1 < problemsLen">
                <i-button type="primary" @click="fetchData" size="large" icon="ios-skipforward">下一题</i-button>
            </div>
            <div v-if="globalIndex+1 === problemsLen">
                <i-button type="primary" @click="submit" size="large">提交答案</i-button>
            </div>
        </i-col>
    </Row>
    <br>
    <hr>
    <Button-group>

        <i-button v-for="n in problemsLen" :type="n-1 > globalIndex ? 'ghost':'success'" size="large">{{n}}</i-button>
    </Button-group>
    <Modal v-model="submitSuccess" title="提交成功" @on-ok="goToExercise" @on-cancel="goToExercise" :closable="false">
        <p>提交成功,请等待老师批改</p>
    </Modal>
</div>
<%@include file="../js.jsp" %>
<script src="static/dateFormat.js"></script>
<script>
    new Vue({
        el: '#app',
        data: {
            exerciseId:${exerciseId},
            problems: [],
            pageSize: 1,
            currentProblem: {},
            problemsLen: 0,
            globalIndex: 0,          //全局 index, 指向当前答题的 index, 便于绑定 submitAnswer
            submitAnswers: [],      //所有题目的详细答案,包括开始 结束时间
            answer: '',             //题目答案
            message: false,
            problemsId: [], //向后台传递本次练习的problemId,
            submitSuccess: false
        },
        methods: {
            getProblemsByExerciseId(exerciseId) {
                $.ajax({
                    type: 'get',
                    url: '${pageContext.request.contextPath}/student/exercise/' + exerciseId + '/problems',
                    dataType: 'json',
                    success: function (data) {
                        this.problems = data;
                        this.currentProblem = this.problems[0];
                        this.problemsLen = this.problems.length;
                        this.submitAnswers.push({
                            startTime: new Date().Format("yyyy-MM-dd HH:mm:ss"),
                            endTime: '',
                            answer: ''
                        });
                        this.problemsId.push(this.currentProblem.problemId);

                    }.bind(this),
                    error: function (err) {
                        console.log(err);
                    }
                });
            },
            //获取题目,并处理答题时间(写入上一题的结束时间,写入下一题的开始时间)
            fetchData: function () {
                //检测当前题目是否完成,若未完成,则不刷新页面,直至完成
                if (this.answer === '') {
                    this.$Notice.config({
                        top: 80,
                        duration: 3
                    });
                    this.message = true;
                    this.$Notice.warning({
                        title: '当前题目还没有完成!',
                        top: 40
                    });
                    return;
                }
                this.submitAnswers[this.globalIndex].endTime = new Date().Format("yyyy-MM-dd HH:mm:ss");
                this.submitAnswers[this.globalIndex].answer = this.answer;
                this.submitAnswers.push({startTime: new Date().Format("yyyy-MM-dd HH:mm:ss"), endTime: '', answer: ''});
                this.answer = '';
                this.globalIndex++;
                this.currentProblem = this.problems[this.globalIndex];
                this.problemsId.push(this.currentProblem.problemId);
            },
            submit: function () {
                //进度条
                this.$Loading.start();
                //处理最后一题
                this.submitAnswers[this.globalIndex].answer = this.answer;
                this.submitAnswers[this.globalIndex].endTime = new Date().Format("yyyy-MM-dd HH:mm:ss");
                //当前用户的答案
                let data = {
                    'userId':${sessionScope.account.userId},
                    'exerciseId': this.exerciseId,
                    'answers': this.submitAnswers,
                    'problemsId': this.problemsId
                };
                //持久化
                $.ajax({
                    type: 'POST',
                    url: '${pageContext.request.contextPath}/student/exercise/submitAnswers',
                    data: JSON.stringify(data),
                    contentType: "application/json",
                    dataType: 'json',
                    success: function (data) {
                        this.$Loading.finish();
                        if (data === true) {
                            this.submitSuccess = true;
                        } else {
                            alert("提交失败!请重新提交或联系老师")
                        }

                    }.bind(this),
                    error: function (err) {
                        console.log(err);
                    }
                });
            },
            goToExercise: function () {
                window.location.href = "${pageContext.request.contextPath}/student/exerciseManage"
            }

        },
        //页面加载完成后获取 exerciseId 下的 全部problem
        mounted: function () {
            this.getProblemsByExerciseId(this.exerciseId);
        },
        filters: {

            formatChoose: function (index) {
                return String.fromCharCode(index + 65);
            }
        }
    })
</script>
<script>
    new Vue({
        el: "#student-exercise",
        data: {
            isActive: true
        }
    })

</script>
</body>
</html>