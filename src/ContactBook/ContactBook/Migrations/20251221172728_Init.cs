using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ContactBook.Migrations
{
    /// <inheritdoc />
    public partial class Init : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "contact_book");

            migrationBuilder.CreateTable(
                name: "Contacts",
                schema: "contact_book",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    first_name = table.Column<string>(type: "varchar(256)", nullable: false),
                    last_name = table.Column<string>(type: "varchar(256)", nullable: false),
                    email = table.Column<string>(type: "varchar(256)", nullable: false),
                    phone = table.Column<string>(type: "varchar(16)", nullable: false),
                    path = table.Column<string>(type: "varchar(256)", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamptz", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Contacts", x => x.id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Contacts",
                schema: "contact_book");
        }
    }
}
