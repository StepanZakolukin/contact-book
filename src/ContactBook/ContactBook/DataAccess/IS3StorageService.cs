namespace ContactBook.DataAccess;

public interface IS3StorageService
{
    public Task SaveFileAsync(
        Stream fileStream,
        string path,
        string contentType,
        CancellationToken cancellationToken
    );

    public Task<string> GetPreSignedURL(string path, TimeSpan validFor);

    public Task DeleteFileAsync(string path, CancellationToken cancellationToken);
}
