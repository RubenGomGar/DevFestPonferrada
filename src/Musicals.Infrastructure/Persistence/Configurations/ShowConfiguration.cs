using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Musicals.Domain.Shows;

namespace Musicals.Infrastructure.Persistence.Configurations;

internal sealed class ShowConfiguration : IEntityTypeConfiguration<Show>
{
    public void Configure(EntityTypeBuilder<Show> builder)
    {
        builder.ToTable("Shows");
        builder.HasKey(s => s.Id);
        builder.Property(s => s.Title).HasMaxLength(Show.TitleMaxLength).IsRequired();
        builder.Property(s => s.Composer).HasMaxLength(Show.ComposerMaxLength).IsRequired();
        builder.Property(s => s.CreatedAt).IsRequired();
    }
}
