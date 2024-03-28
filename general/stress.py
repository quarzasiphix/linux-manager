import asyncio
import aiohttp
import time

# Number of requests to send
num_requests = 500

# URL of the server to send requests to
server_url = "https://franobrand.pl"

# Function to send HTTP request
async def send_request(session):
    start_time = time.time()
    async with session.get(server_url) as response:
        response_time = time.time() - start_time
        status_code = response.status
        return status_code, response_time

# Function to send multiple requests concurrently
async def send_requests():
    async with aiohttp.ClientSession() as session:
        tasks = [send_request(session) for _ in range(num_requests)]
        return await asyncio.gather(*tasks)

# Main function

async def main():
    # Send requests concurrently
    req = 0
    while True:
        print("\nSending requests... please wait\n")
        results = await send_requests()
        for status_code, response_time in results:
            req += 1
            print(f"Req: {req}, Status Code: {status_code}, Response Time: {response_time:.2f} seconds")
        req = 0
# Run the main function
asyncio.run(main())
