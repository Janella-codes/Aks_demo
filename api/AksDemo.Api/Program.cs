var builder = WebApplication.CreateBuilder(args);

// ⭐ REQUIRED FOR DOCKER ⭐
builder.WebHost.UseKestrel()
    .UseUrls("http://0.0.0.0:80");

// Allow Angular dev server
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAngular",
        policy => policy
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod());
});

var app = builder.Build();

app.UseCors("AllowAngular");

// ❌ Do NOT use HTTPS redirection inside Docker
// app.UseHttpsRedirection();

app.MapGet("/", () => "AKS Demo API is running");

app.Run();
