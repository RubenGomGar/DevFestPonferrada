using Microsoft.EntityFrameworkCore;
using Musicales.Domain.Obras;

namespace Musicales.Infrastructure.Persistence;

public sealed class MusicalesDbContext(DbContextOptions<MusicalesDbContext> options) : DbContext(options)
{
    public DbSet<Obra> Obras => Set<Obra>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        ArgumentNullException.ThrowIfNull(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(MusicalesDbContext).Assembly);
    }
}
