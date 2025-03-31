FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
# copy csproj and restore as distinct layers
COPY SampleWebApiAspNetCore/*.csproj .
RUN dotnet restore
# copy everything else and build app
COPY SampleWebApiAspNetCore/ .
RUN dotnet publish SampleWebApiAspNetCore.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "SampleWebApiAspNetCore.dll"]
