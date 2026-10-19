using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Musicales.Domain.Obras;

namespace Musicales.Infrastructure.Persistence.Configurations;

internal sealed class ObraConfiguration : IEntityTypeConfiguration<Obra>
{
    public void Configure(EntityTypeBuilder<Obra> builder)
    {
        builder.ToTable("Obras");
        builder.HasKey(o => o.Id);
        builder.Property(o => o.Titulo).HasMaxLength(Obra.TituloMaxLength).IsRequired();
        builder.Property(o => o.Compositor).HasMaxLength(Obra.CompositorMaxLength).IsRequired();
        builder.Property(o => o.CreadaEn).IsRequired();
    }
}
