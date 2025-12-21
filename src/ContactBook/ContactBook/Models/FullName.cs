using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace ContactBook.Models;

[Owned]
public record FullName
{
    [Column("first_name", TypeName = "varchar(256)")]
    public required string FirstName { get; init; }
    
    [Column("last_name", TypeName = "varchar(256)")]
    public required string LastName { get; init; }
}