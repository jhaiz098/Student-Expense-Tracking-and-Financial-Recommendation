export default {
	async fetch(request, env, ctx): Promise<Response> {

		const corsHeaders = {
			"Access-Control-Allow-Origin": "*",
			"Access-Control-Allow-Methods": "POST, OPTIONS",
			"Access-Control-Allow-Headers": "Content-Type",
		};


		// Handle browser/app permission check
		if (request.method === "OPTIONS") {
			return new Response(null, {
				headers: corsHeaders,
			});
		}


		// Allow only POST
		if (request.method !== "POST") {
			return new Response(
				"Advisor API is running.",
				{
					status: 200,
					headers: corsHeaders,
				}
			);
		}


		try {

			const data = await request.json();

			console.log("Received data:", data);


			const response = {
				advice:
					"Your spending looks stable, but your food expenses should be monitored.",
				received_data: data,
			};


			return new Response(
				JSON.stringify(response),
				{
					headers: {
						...corsHeaders,
						"Content-Type": "application/json",
					},
				}
			);


		} catch (error) {

			return new Response(
				JSON.stringify({
					error: "Invalid request.",
				}),
				{
					status: 400,
					headers: {
						...corsHeaders,
						"Content-Type": "application/json",
					},
				}
			);
		}
	},
} satisfies ExportedHandler<Env>;