using System.ComponentModel.DataAnnotations;
using ContactBook.Models;

namespace ContactBook.Controllers;

public class UpdateContactRequest
{
    public required FullName FullName { get; init; }
    
    [EmailAddress]
    public required string Email { get; init; }
    
    [Phone]
    public required string Phone { get; init; }
}