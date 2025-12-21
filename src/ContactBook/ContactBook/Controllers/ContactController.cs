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
    private readonly ContactContext _context;
    public ContactController(ContactContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAllContacts()
    {
        var list = new List<GetContactResponse>();
        
        foreach (var contact in await _context.Contacts.ToArrayAsync())
        {
            //TODO: получаем ссылку на картинку контакта если она есть

            var response = new GetContactResponse
            {
                FullName = contact.FullName,
                Email = contact.Email,
                Phone = contact.Phone,
                PhotoUrl = default
            };
            
            list.Add(response);
        }
        
        return Ok(list);
    }
    
    [HttpGet("{contact-id:guid}")]
    public async Task<IActionResult> GetContact([FromRoute(Name = "contact-id")] Guid contactId)
    {
        var contact = await _context.Contacts.FindAsync(contactId);
        
        //TODO: получить временный url фото по пути в object-storage
        
        if (contact == null)
            return NotFound();

        return Ok(new GetContactResponse
        {
            FullName = contact.FullName,
            Email = contact.Email,
            Phone = contact.Phone,
            PhotoUrl = default
        });
    }

    [HttpPost]
    public async Task<IActionResult> CreateContact([FromForm] CreateContactRequest request)
    {
        //TODO: загружаем файл в object-storage если его передали и сохраняем путь до него в модели
        
        var contact = new Contact
        {
            FullName = request.FullName,
            Email = request.Email,
            Phone = request.Phone,
            Photo = new Photo
            {
                Path = default
            }
        };
        
        await _context.Contacts.AddAsync(contact);
        await _context.SaveChangesAsync();

        return Ok(contact.Id);
    }
    
    [HttpDelete("{contact-id:guid}")]
    public async Task<IActionResult> DeleteContact([FromRoute(Name = "contact-id")] Guid contactId)
    {
        var contact = await _context.Contacts.FindAsync(contactId);
        if (contact == null)
            return NotFound();
        
        _context.Contacts.Remove(contact);
        
        //TODO: удалить файл если есть
        
        await _context.SaveChangesAsync();
        
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
        [MaxFileSize(5 * 1024 * 1024), AllowedExtensions([".jpg", ".jpeg", ".png"])] IFormFile photo)
    {
        var contact = await _context.Contacts.FindAsync(contactId);

        if (contact == null) return NotFound();
        
        //TODO: удаляем старый, загружаем новый файл. Получаем ссылку на файл, отправляем в ответе
        
        return Ok();
    }
}