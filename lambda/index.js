const aws = require('aws-sdk');

exports.handler = async (event, context, callback) => {
    const stepfunctions = new aws.StepFunctions();

    for (const record of event.Records) {
        const messageBody = JSON.parse(record.body);
        const taskToken = messageBody.TaskToken;

        const params = {
            output: "\"Callback task completed successfully.\"",
            taskToken: taskToken
        };

        console.log(`Calling Step Functions to complete callback task with params ${JSON.stringify(params)}`);

        stepfunctions.sendTaskSuccess(params, (err, data) => {
            console.log('hereherehere');
            if (err) {
                console.error(err.message);
                callback(err.message);
                return;
            }
            console.log('hereherehere2');
            console.log(data);
            console.log('hereherehere3');
            console.log(data);
            callback(null);
        });
    }
};
