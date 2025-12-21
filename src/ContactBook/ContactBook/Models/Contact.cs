using System.ComponentModel.DataAnnotations.Schema;

namespace ContactBook.Models;

public class Contact
{
    [Column("id", TypeName = "uuid")]
    public Guid Id { get; set; } = Guid.NewGuid();
    
    public required FullName FullName { get; set; }
    
    [Column("email", TypeName = "varchar(256)")]
    public required string Email { get; set; }
    
    [Column("phone", TypeName = "varchar(16)")]
    public required string Phone { get; set; }
    
    public Photo? Photo { get; set; }
    
    [Column("created_at", TypeName = "timestamptz")]
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
}