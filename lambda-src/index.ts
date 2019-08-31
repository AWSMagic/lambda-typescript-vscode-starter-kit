export const handler = async (event: any = {}, content: any = {}): Promise<any> => {
  console.log('value1 =', event.key1);
  console.log('value2 =', event.key2);
  console.log('value3 =', event.key3);
  console.log(process.env.Stage);
  const response = JSON.stringify(event, null, 2);
  return response;
}