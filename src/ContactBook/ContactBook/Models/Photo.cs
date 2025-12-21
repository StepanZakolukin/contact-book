using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace ContactBook.Models;

[Owned]
public record Photo
{
    [Column("path", TypeName = "varchar(256)")]
    public required string Path { get; init; }
}