using ContactBook.Controllers.DataAnnotation;
using ContactBook.DataAccess;
using ContactBook.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ContactBook.Controllers;

[ApiController]
[Route("api/contacts")]
public class ContactController : ControllerBase
{
    private const string PathToPhotos = "photo";
    private readonly ContactContext _context;
    private readonly IS3StorageService _storageService;
    
    public ContactController(ContactContext context, IS3StorageService storageService)
    {
        _context = context;
        _storageService = storageService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAllContacts()
    {
        var list = new List<GetContactResponse>();
        
        foreach (var contact in await _context.Contacts.ToArrayAsync())
            list.Add(await ConvertToGetContactResponse(contact));
        
        return Ok(list);
    }
    
    [HttpGet("{contact-id:guid}")]
    public async Task<IActionResult> GetContact([FromRoute(Name = "contact-id")] Guid contactId)
    {
        var contact = await _context.Contacts.FindAsync(contactId);

        return contact == null ? NotFound() : Ok(await ConvertToGetContactResponse(contact));
    }

    [HttpPost]
    public async Task<IActionResult> CreateContact([FromForm] CreateContactRequest request,
        CancellationToken cancellationToken)
    {
        var fileIsNotEmpty = request.Photo is not null && request.Photo.Length != 0;
        
        string? path = null;
        if (fileIsNotEmpty)
        {
            path = Path.Combine(PathToPhotos, $"{Guid.NewGuid()}", Path.GetExtension(request.Photo!.FileName));
            await SaveFileAsync(request.Photo, path, cancellationToken);
        }
        
        var contact = new Contact
        {
            FullName = request.FullName,
            Email = request.Email,
            Phone = request.Phone,
            Photo = fileIsNotEmpty ? new Photo {Path = path!} : null
        };
        
        await _context.Contacts.AddAsync(contact, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);

        return Ok(contact.Id);
    }
    
    [HttpDelete("{contact-id:guid}")]
    public async Task<IActionResult> DeleteContact([FromRoute(Name = "contact-id")] Guid contactId,
        CancellationToken cancellationToken)
    {
        var contact = await _context.Contacts.FindAsync([contactId], cancellationToken: cancellationToken);
        if (contact == null)
            return NotFound();
        
        _context.Contacts.Remove(contact);
        
        if (contact.Photo != null)
            await _storageService.DeleteFileAsync(contact.Photo.Path, cancellationToken);
        
        await _context.SaveChangesAsync(cancellationToken);
        
        return NoContent();
    }

    [HttpPost("{contact-id:guid}")]
    public async Task<IActionResult> UpdateContact([FromRoute(Name = "contact-id")] Guid contactId,
        [FromForm] UpdateContactRequest request)
    {
        var contact = await _context.Contacts.FindAsync(contactId);

        if (contact == null) return NotFound();
        
        contact.Phone = request.Phone;
        contact.FullName = request.FullName;
        contact.Email = request.Email;

        await _context.SaveChangesAsync();
        
        return NoContent();
    }

    [HttpPost("{contact-id:guid}/photo")]
    public async Task<IActionResult> UpdatePhoto([FromRoute(Name = "contact-id:guid")] Guid contactId,
        [MaxFileSize(5 * 1024 * 1024), AllowedExtensions([".jpg", ".jpeg", ".png"])] IFormFile photo,
        CancellationToken cancellationToken)
    {
        if (photo is null || photo.Length == 0)
            return BadRequest("Загружен пустой файл");
        
        var contact = await _context.Contacts.FindAsync([contactId], cancellationToken);

        if (contact == null) return NotFound();

        if (contact.Photo != null)
            await _storageService.DeleteFileAsync(contact.Photo.Path, cancellationToken);
        else
            contact.Photo = new Photo { Path = Path.Combine(PathToPhotos, $"{Guid.NewGuid()}", Path.GetExtension(photo.FileName)) };
        
        await SaveFileAsync(photo, contact.Photo.Path, cancellationToken);
        
        return Ok(await _storageService.GetPreSignedURL(contact.Photo!.Path, TimeSpan.FromHours(3)));
    }

    private async Task<GetContactResponse> ConvertToGetContactResponse(Contact contact)
    {
        var photoUrl = string.Empty;
        if (contact.Photo != null)
            photoUrl = await _storageService.GetPreSignedURL(contact.Photo.Path, TimeSpan.FromHours(3));

        return new GetContactResponse
        {
            FullName = contact.FullName,
            Email = contact.Email,
            Phone = contact.Phone,
            PhotoUrl = photoUrl == string.Empty ? null : photoUrl,
        };
    }

    private async Task SaveFileAsync(IFormFile file, string path, CancellationToken cancellationToken)
    {
        using var memoryStream = new MemoryStream();
        await file.CopyToAsync(memoryStream, cancellationToken);
        memoryStream.Position = 0;
        
        await _storageService.SaveFileAsync(memoryStream, path, file.ContentType, cancellationToken);
    }
}