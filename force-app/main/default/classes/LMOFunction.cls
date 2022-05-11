/**
 * An apex wrapper class for Functions invocation
 */
public with sharing class LMOFunction {

    private static FunctionStore obj = new FunctionStore();

    public static functions.Function get(String functionName){
        obj.functionName = functionName;
        return functions.Function.get(functionName);
    }

    public static functions.FunctionInvocation invoke(String payload) {
        System.debug('functionName:' + obj.functionName);
        datetime start = system.now();
        string startTime = start.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
		functions.Function accountFunction = functions.Function.get(obj.functionName);
		functions.FunctionInvocation invocation = accountFunction.invoke(payload);
        datetime finish = system.now();
        string finishTime = finish.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        functionInvocation__e evt = new functionInvocation__e(Id__c=obj.guid, Start_Time__c=startTime, End_Time__c=finishTime, Invocation_Type__c=false, Duration__c=finish.getTime()-start.getTime());
        EventBus.publish(evt);
        System.debug(evt);
        return invocation;
    }

    public static functions.FunctionInvocation invoke(String payload, String CallableClass) {
        System.debug('functionName:' + obj.functionName);
        obj.CallableClass = CallableClass;
        datetime start = system.now();
        obj.start = start;
        string startTime = start.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        functionInvocation__e evt = new functionInvocation__e(Id__c=obj.guid, Start_Time__c=startTime, Invocation_Type__c=true);
        // EventBus.publish(evt);
        System.debug(evt);
		functions.Function accountFunction = functions.Function.get(obj.functionName);
		functions.FunctionInvocation invocation = accountFunction.invoke(payload, new FunctionStore(CallableClass, start, evt)); // ofCallable
        return invocation;
    }

	public class FunctionStore implements functions.FunctionCallback {
        String Id = '';
        Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertTohex(b);
		String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        String functionName = '';
        String CallableClass = '';
        functionInvocation__e asyncFuncEvt;
        datetime start;

        public FunctionStore(){}
        public FunctionStore(String cc, datetime strt, functionInvocation__e evt){
            CallableClass = cc;
            asyncFuncEvt = evt;
            start = strt;
        }

        public void handleResponse(functions.FunctionInvocation result) {
            // Handle result of function invocation
            String jsonResponse = result.getResponse();
            System.debug('Got response in FunctionStore ' + jsonResponse);
            Callable extension = (Callable) Type.forName(CallableClass).newInstance();
            extension.call('handleResponse', new Map<String, Object> { 'result' => result });

            system.debug('start:' + start);
            datetime finish = system.now();
            string finishTime = finish.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
            asyncFuncEvt.End_Time__c = finishTime;
            asyncFuncEvt.Duration__c = finish.getTime()-start.getTime();
            system.debug(asyncFuncEvt);
        	EventBus.publish(asyncFuncEvt);

            // Log error, if applicable
            if (result.getStatus() == functions.FunctionInvocationStatus.ERROR) {
                functions.FunctionInvocationError resultError = result.getError();
                if (resultError != null) {
                    System.debug('Error type: ' + resultError.getType());
                    System.debug('Error message: ' + resultError.getMessage());
                } else {
                    System.debug('Error: UNKNOWN');
                }
                return;
            }
        }
	}

}
