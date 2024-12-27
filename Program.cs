using RtspClientSharp;
using System.Diagnostics;

internal class Program
{
    private static async Task Main(string[] args)
    {
        // Configurações
        string hostname = "1.1.1.1";
        string username = "xxxx";
        string password = "yyyyy";
        int port = 554; // Porta padrão do RTSP

        var rtspUrl = $"rtsp://{username}:{password}@{hostname}:{port}/cam/realmonitor?channel=1&subtype=1";

        var connectionParameters = new ConnectionParameters(new Uri(rtspUrl));

        var client = new RtspClient(connectionParameters);

        try
        {
            Console.WriteLine("Conectando ao stream RTSP...");

            await client.ConnectAsync(CancellationToken.None);
            Console.WriteLine("Conectado ao stream RTSP!");

            OpenStreamWithFFmpeg(rtspUrl);

            Console.WriteLine("Conexão ativa. Aguardando 10 segundos...");
            await Task.Delay(TimeSpan.FromSeconds(10));

            Console.WriteLine("Encerrando conexão...");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Erro ao conectar: {ex.Message}");
        }
        finally
        {
            client.Dispose();
            Console.WriteLine("Conexão encerrada.");
        }
    }

    private static void OpenStreamWithFFmpeg(string rtspUrl)
    {
        string outputFile = "/videos/output_video.mp4";

        var ffmpegProcess = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = "/usr/bin/ffmpeg",
                Arguments = $"-rtsp_transport tcp -probesize 5000000 -analyzeduration 10000000 -i {rtspUrl} -t 15 -vcodec libx264 -c:v libx264 -preset fast -f mp4 {outputFile}",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                UseShellExecute = false
            }
        };

        // Captura de saída e erro do FFmpeg
        ffmpegProcess.OutputDataReceived += (sender, e) => Console.WriteLine($"[stdout] {e.Data}");
        ffmpegProcess.ErrorDataReceived += (sender, e) => Console.WriteLine($"[stderr] {e.Data}");

        try
        {
            ffmpegProcess.Start();
            ffmpegProcess.BeginOutputReadLine();
            ffmpegProcess.BeginErrorReadLine();
            ffmpegProcess.WaitForExit();
            Console.WriteLine("FFmpeg concluído!");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Erro ao executar FFmpeg: {ex.Message}");
        }
    }
}