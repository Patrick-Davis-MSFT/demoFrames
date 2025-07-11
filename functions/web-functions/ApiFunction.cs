using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using System.Text.Json;

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
        _logger.LogInformation("heartbeat request");
        var retVal = new { status = "alive - " + DateTime.Now.ToString() };
        return new OkObjectResult(retVal); // ASP.NET Core will serialize this automatically
    }
}