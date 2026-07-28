# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY AksDemo.Api/*.csproj .
RUN dotnet restore

COPY AksDemo.Api/. .
RUN dotnet publish -c Release -o /app

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .

EXPOSE 80
ENTRYPOINT ["dotnet", "AksDemo.Api.dll"]
