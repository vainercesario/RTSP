# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# This stage is used when running from VS in fast mode (Default for Debug configuration)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS base
USER root
WORKDIR /app

RUN apt-get update && apt-get install -y ffmpeg libsdl2-2.0-0 libsdl2-dev \
    && ffmpeg -version \
    && mkdir -p /videos && chmod -R 777 /videos

# Criar o diret�rio de v�deos e garantir permiss�es
RUN mkdir -p /videos && chmod -R 777 /videos

# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["/RTSP.csproj", "./"]
RUN dotnet restore "./RTSP.csproj"
COPY . .
WORKDIR "/src"
RUN dotnet build "./RTSP.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./RTSP.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

RUN chmod -R 777 /videos

ENTRYPOINT ["dotnet", "RTSP.dll"]