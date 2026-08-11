using System.Diagnostics;
using System.Diagnostics.Metrics;

namespace FastFood.Observability.Common;

public class ObservabilityBase : IObservability
{

  protected ObservabilityBase(string serviceName, string activitySourceName, string? version = null)
  {
    this.ServiceName = serviceName;
    this.Meter = new Meter(this.ServiceName, version);
    this.ActivitySourceName = activitySourceName;
    this.ActivitySource = new ActivitySource(activitySourceName, version);
    
    // Initialize feature flag metrics
    this.FeatureEvaluationCounter = this.Meter.CreateCounter<long>(
        "feature.evaluation",
        description: "Number of feature flag evaluations");
    
    this.FeatureUsageCounter = this.Meter.CreateCounter<long>(
        "feature.usage",
        description: "Number of times features are actively used");
  }

  public string ServiceName { get; }
  
  public Counter<long> FeatureEvaluationCounter { get; }
  
  public Counter<long> FeatureUsageCounter { get; }

  protected Meter Meter { get; }

  public string ActivitySourceName { get; }

  public virtual Activity? StartActivity(string name = "", ActivityKind kind = ActivityKind.Internal)
  {
    return this.ActivitySource.StartActivity(name, kind);
  }

  public virtual Activity? StartActivity(
    Type? callerType,
    string name = "",
    ActivityKind kind = ActivityKind.Internal,
    bool includeCallerTypeInName = false)
  {
    if (callerType is not null && this.StartActivityExclusionPredicate(callerType))
      return null;
    if (!includeCallerTypeInName || callerType is null)
      return this.ActivitySource.StartActivity(name, kind);
    string activityName;
    if (!callerType.IsGenericType)
      activityName = $"{callerType.Name}.{name}";
    else
      activityName = $"{callerType.Name.AsSpan(0, callerType.Name.IndexOf('`')).ToString()}<{string.Join(",", callerType.GenericTypeArguments.Select(t => t.Name))}>.{name}";
    return this.ActivitySource.StartActivity(activityName, kind);
  }

  protected virtual Func<Type, bool> StartActivityExclusionPredicate { get; } = _ => false;

  protected virtual bool EnableDatabaseMetrics { get; } = true;

  protected virtual ActivitySource ActivitySource { get; }
}
