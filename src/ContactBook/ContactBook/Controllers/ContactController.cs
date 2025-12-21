using Microsoft.AspNetCore.Mvc;

namespace ContactBook.Controllers;

[ApiController]
[Route("api/contacts")]
public class ContactController : ControllerBase
{
    [HttpGet("{contact-id:guid}")]
    public IActionResult GetContact([FromRoute(Name = "contact-id")] Guid contactId)
    {
        throw new NotImplementedException();
    }

    [HttpPost]
    public IActionResult CreateContact()
    {
        throw new NotImplementedException();
    }
    
    [HttpDelete("{contact-id:guid}")]
    public IActionResult DeleteContact([FromRoute(Name = "contact-id")] Guid contactId)
    {
        throw new NotImplementedException();
    }

    [HttpPost("{contact-id:guid}")]
    public IActionResult UpdateContact([FromRoute(Name = "contact-id")] Guid contactId)
    {
        throw new NotImplementedException();
    }
}