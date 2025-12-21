using ContactBook.Models;
using Microsoft.EntityFrameworkCore;

namespace ContactBook.DataAccess;

public class ContactContext : DbContext
{
    public ContactContext(DbContextOptions<ContactContext> options) : base(options)
    {
    }
    
    public DbSet<Contact> Contacts => Set<Contact>();
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        modelBuilder.HasDefaultSchema("contact_book");
        
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ContactContext).Assembly);
    }
}