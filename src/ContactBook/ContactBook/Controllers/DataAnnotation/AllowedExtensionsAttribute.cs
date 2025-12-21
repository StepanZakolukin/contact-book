using System.ComponentModel.DataAnnotations;

namespace ContactBook.Controllers.DataAnnotation;

public class AllowedExtensionsAttribute : ValidationAttribute
{
    private readonly string[] _extensions;
    
    public AllowedExtensionsAttribute(string[] extensions)
    {
        _extensions = extensions;
    }
    
    protected override ValidationResult IsValid(
        object value, ValidationContext validationContext)
    {
        if (value is IFormFile file)
        {
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            
            if (!_extensions.Contains(extension))
            {
                return new ValidationResult(
                    GetErrorMessage(file.FileName));
            }
        }
        else if (value is IEnumerable<IFormFile> files)
        {
            foreach (var f in files)
            {
                var extension = Path.GetExtension(f.FileName).ToLowerInvariant();
                
                if (!_extensions.Contains(extension))
                {
                    return new ValidationResult(
                        GetErrorMessage(f.FileName));
                }
            }
        }
        
        return ValidationResult.Success;
    }
    
    private string GetErrorMessage(string fileName)
    {
        return $"Файл '{fileName}' имеет недопустимое расширение. Разрешены: {string.Join(", ", _extensions)}";
    }
}