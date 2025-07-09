using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace web_functions;

public class ApiFunction
{
    private readonly ILogger<ApiFunction> _logger;

    public ApiFunction(ILogger<ApiFunction> logger)
    {
        _logger = logger;
    }

    [Function("Heartbeat")]
    public IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");
        return new OkObjectResult("Alive: " + DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss"));
    }
}