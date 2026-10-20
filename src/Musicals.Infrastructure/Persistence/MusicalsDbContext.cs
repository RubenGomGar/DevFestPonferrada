using Microsoft.EntityFrameworkCore;
using Musicals.Domain.Shows;

namespace Musicals.Infrastructure.Persistence;

public sealed class MusicalsDbContext(DbContextOptions<MusicalsDbContext> options) : DbContext(options)
{
    public DbSet<Show> Shows => Set<Show>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        ArgumentNullException.ThrowIfNull(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(MusicalsDbContext).Assembly);
    }
}
