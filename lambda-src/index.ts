export const handler = async (event: any = {}, content: any = {}): Promise<any> => {
  let response: object;
  let message: string = 'Hello World!';

  if (event.queryStringParameters && event.queryStringParameters.message) {
    console.log("API - Received message: " + event.queryStringParameters.message);
    message = event.queryStringParameters.message;
  } else if (event.message) {
    console.log('Invoke - Received message:', event.message);
    message = event.message;
  }

  if (event) {
    console.log(`event: ${JSON.stringify(event)}`);
  }  
  
  console.log(process.env.Stage);
  
  try {
    response = {
      'statusCode': 200,
      'body': JSON.stringify({
        'message': message
      })
    }    
  } catch(err) {
    console.log(err);
    return err;
  }

  return response;
}
