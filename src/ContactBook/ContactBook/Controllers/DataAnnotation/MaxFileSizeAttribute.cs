using System.ComponentModel.DataAnnotations;

namespace ContactBook.Controllers.DataAnnotation;

public class MaxFileSizeAttribute : ValidationAttribute
{
    private readonly int _maxFileSize;
    
    public MaxFileSizeAttribute(int maxFileSize)
    {
        _maxFileSize = maxFileSize;
    }
    
    protected override ValidationResult IsValid(
        object value, ValidationContext validationContext)
    {
        if (value is IFormFile file)
        {
            if (file.Length > _maxFileSize)
            {
                return new ValidationResult(
                    GetErrorMessage(file.FileName));
            }
        }
        else if (value is IEnumerable<IFormFile> files)
        {
            foreach (var formFile in files)
            {
                if (formFile.Length > _maxFileSize)
                {
                    return new ValidationResult(
                        GetErrorMessage(formFile.FileName));
                }
            }
        }
        
        return ValidationResult.Success;
    }
    
    private string GetErrorMessage(string fileName)
    {
        return $"Файл '{fileName}' превышает максимальный размер {_maxFileSize / (1024 * 1024)}MB.";
    }
}