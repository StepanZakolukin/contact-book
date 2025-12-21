using System.ComponentModel.DataAnnotations;
using ContactBook.Controllers.DataAnnotation;
using ContactBook.Models;

namespace ContactBook.Controllers;

public record CreateContactRequest
{
    public required FullName FullName { get; init; }
    
    [EmailAddress]
    public required string Email { get; init; }
    
    [Phone]
    public required string Phone { get; init; }
    
    [MaxFileSize(5 * 1024 * 1024)]
    [AllowedExtensions([".jpg", ".jpeg", ".png"])]
    public required IFormFile Photo { get; init; }
}