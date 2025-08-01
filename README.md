# proyecto07


{
  "Comment": "An example of the Amazon States Language for starting a callback with SQS",
  "StartAt": "Check Inventory",
  "States": {
    "Check Inventory": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sqs:sendMessage.waitForTaskToken",
      "Parameters": {
        "QueueUrl": "<INSERT SQS QUEUE URL HERE>",
        "MessageBody": {
          "MessageTitle": "Callback Task started by Step Function",
          "TaskToken.$": "$$.Task.Token"
        }
      },
      "Next": "Notify Success",
      "Catch": [
        {
          "ErrorEquals": [ "States.ALL" ],
          "Next": "Notify Failure"
        }
      ]
    },
      "Notify Success": {
        "Type": "Pass",
        "Result": "Callback Task started by Step Functions succeeded",
        "End": true
      },
      "Notify Failure": {
        "Type": "Pass",
        "Result": "Callback Task started by Step Functions failed",
        "End": true
      }
  }
}



 