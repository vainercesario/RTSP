FROM mcr.microsoft.com/dotnet/runtime:8.0 AS base
USER root
WORKDIR /app

RUN apt-get update && apt-get install -y ffmpeg libsdl2-2.0-0 libsdl2-dev \
    && ffmpeg -version \
    && mkdir -p /videos && chmod -R 777 /videos

RUN mkdir -p /videos && chmod -R 777 /videos

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["/RTSP.csproj", "./"]
RUN dotnet restore "./RTSP.csproj"
COPY . .
WORKDIR "/src"
RUN dotnet build "./RTSP.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./RTSP.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

RUN chmod -R 777 /videos

ENTRYPOINT ["dotnet", "RTSP.dll"]
