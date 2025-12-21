using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;

namespace ContactBook.DataAccess;

public class YandexS3StorageService : IS3StorageService
{
    private readonly string bucketName;
    private readonly AmazonS3Client s3Client;

    public YandexS3StorageService(IConfiguration config)
    {
        bucketName = config["YandexS3:BucketName"];
        var amazonConfig = new AmazonS3Config { ServiceURL = "https://s3.yandexcloud.net", ForcePathStyle = true };

        s3Client = new AmazonS3Client(
            new BasicAWSCredentials(config["YandexS3:AccessKey"], config["YandexS3:SecretKey"]),
            amazonConfig);
    }

    public Task<string> GetPreSignedURL(string path, TimeSpan validFor)
    {
        var request = new GetPreSignedUrlRequest
        {
            BucketName = bucketName, Key = path, Expires = DateTime.UtcNow.Add(validFor), Verb = HttpVerb.GET
        };

        return s3Client.GetPreSignedURLAsync(request);
    }

    public async Task DeleteFileAsync(string path, CancellationToken cancellationToken)
    {
        var removeRequest = new DeleteObjectRequest { BucketName = bucketName, Key = path };

        await s3Client.DeleteObjectAsync(removeRequest, cancellationToken);
    }

    public async Task SaveFileAsync(
        Stream fileStream,
        string path,
        string contentType,
        CancellationToken cancellationToken
    )
    {
        var putRequest = new PutObjectRequest
        {
            BucketName = bucketName,
            Key = path,
            InputStream = fileStream,
            ContentType = contentType,
            CannedACL = S3CannedACL.PublicRead
        };

        await s3Client.PutObjectAsync(putRequest, cancellationToken);
    }
}
