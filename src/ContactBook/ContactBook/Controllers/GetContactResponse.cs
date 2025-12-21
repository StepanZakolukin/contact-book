using ContactBook.Models;

namespace ContactBook.Controllers;

public record GetContactResponse
{
    public Guid Id { get; init; }
    
    public required FullName FullName { get; init; }
    
    public required string Email { get; init; }

    public required string Phone { get; init; }
    
    public required string? PhotoUrl { get; init; }
}