
const kMessageId1 = "0001";
const kMessageId2 = "0001";

function goToTest1() {
    var param =  {"backRequire":true,"backMethod":"customFunction","messageId":kMessageId1,"messageBody":{"title":"QQ","context":"王者农药如何戒?","url":"https://zhenhuamu.github.io"}};
    var jsonStr = JSON.stringify(param);

    window.webkit.messageHandlers.shareInfo.postMessage(jsonStr);
}

function customFunction(obj){
   var dict =  JSON.parse(obj);

   const messageId =  dict["messageId"];
    var context = dict["status"];

    if (messageId == kMessageId1)
    {
      var param =  {"backRequire":false,"backMethod":"","messageId":kMessageId2,"messageBody":{"status":"回调成功"}};
      var jsonStr = JSON.stringify(param);
      window.webkit.messageHandlers.shareInfo.postMessage(jsonStr);
    }
}

