/**
 * Returns clean error for topup quote
 */
async function cleanTopupQuoteError(error) {
  let errorMessage = ''
  if ([400, 401, 404].includes(error.status)) {
    const result = await error.json()

    if (typeof result.success === 'boolean' && !result.success) {
      // Case 1
      // {"error": { public_address: 'public_address is required and not present in the decoded token' },"success": false}
      errorMessage = typeof result.error === 'string' ? result.error : Object.values(result.error)[0]
    } else if (typeof result.success === 'boolean' && result.error) {
      // Case 2
      // {"error": true,"result": {"error": 'Cannot get quote: Sorry! Looks like this service is not available in your current location.'},
      errorMessage = result.result.error
    } else if (result.message) {
      // Case 3
      // {"errors": [],"message": "Minimum purchase of 33 DAI required.","type": "BadRequestError"}
      errorMessage = result.message
    } else if (result.error && result.error.message) {
      // Case 3
      // {"error":{"statusCode":400,"name":"Bad Request","message":"We are not supporting BUSD bsc network with USD Credit/Debit card"}}
      errorMessage = result.error.message
    } else {
      errorMessage = 'Unknown error'
    }
  }
  return errorMessage
}

export default cleanTopupQuoteError
