public class DemoCallback implements functions.FunctionCallback, Callable {
    public void handleResponse(functions.FunctionInvocation result) {
        // Handle result of function invocation
        String jsonResponse = result.getResponse();
        System.debug('Got response ' + jsonResponse);

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
   // Dispatch actual methods
   public Object call(String action, Map<String, Object> args) {
     switch on action {
       when 'handleResponse' {
           this.handleResponse((functions.FunctionInvocation)args.get('result'));
         return null;
       }
       when else {
        throw new ExtensionMalformedCallException('Method not implemented');
       }
     }
   }
	public class ExtensionMalformedCallException extends Exception {}
}
