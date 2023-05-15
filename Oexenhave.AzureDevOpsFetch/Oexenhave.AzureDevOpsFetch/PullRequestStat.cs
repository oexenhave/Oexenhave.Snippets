using System.Runtime.Serialization;
using Microsoft.TeamFoundation.SourceControl.WebApi;

namespace Oexenhave.AzureDevOpsFetch;

public record PullRequestStat
{
    public string? ProjectName { get; set; }
    
    public string? RepositoryName { get; set; }
    
    public int PullRequestId { get; set; }
    
    [IgnoreDataMember]
    public string? Title { get; set; }
    
    public DateTime CreatedAt { get; set; }
    
    public DateTime ClosedAt { get; set; }
    
    public PullRequestStatus Status { get; set; }

    public double DaysToComplete => (ClosedAt == DateTime.MinValue ? DateTime.Now : ClosedAt).Subtract(CreatedAt).TotalDays;

    public double DaysToCodeReview
    {
        get
        {
            var days = (CodeReviewedAt ?? DateTime.Now).Subtract(CreatedAt).TotalDays;

            // Some PRs have no code approver - and it makes no sense to have it higher that the complete date
            if (days > DaysToComplete)
            {
                return DaysToComplete;
            }

            return days;
        }   
    }
    
    public double DaysToQualityReview => (QualityReviewedAt ?? DateTime.Now).Subtract(CreatedAt).TotalDays;

    public string StatusName
    {
        get
        {
            if (Status == PullRequestStatus.Completed)
            {
                return "Completed";
            }

            if (CodeReviewedAt == null && QualityReviewedAt == null)
            {
                return "AwaitCodeReview";
            }
            
            if (CodeReviewedAt != null && QualityReviewedAt == null)
            {
                return "AwaitQualityReview";
            }
            
            if (CodeReviewedAt != null && QualityReviewedAt != null)
            {
                return "AwaitCompletion";
            }

            return "Unknown";
        }
    }

    public string? Creator { get; set; }
    
    public string? QualityReviewer => QualityReviewerIdentity?.DisplayName;

    public string? CodeReviewer => CodeReviewerIdentity?.DisplayName;
    
    [IgnoreDataMember]
    private IdentityRefWithVote? QualityReviewerIdentity
    {
        get
        {
            return Reviewers?.Where(vote => !vote.IsContainer && vote.VotedFor != null && vote.Vote > 0).FirstOrDefault(vote =>
                vote.VotedFor.First().DisplayName.Contains("Quality") ||
                vote.VotedFor.First().DisplayName.Contains("QA"));
        }
    }
    
    [IgnoreDataMember]
    private IdentityRefWithVote? CodeReviewerIdentity
    {
        get
        {
            return Reviewers?.Where(vote => !vote.IsContainer && vote.Vote > 0 && !vote.UniqueName.Contains("kje@"))
                .FirstOrDefault(vote =>
                    vote.VotedFor == null || (vote.VotedFor != null &&
                                              !vote.VotedFor.First().DisplayName.Contains("Quality") &&
                                              !vote.VotedFor.First().DisplayName.Contains("QA")));
        }
    }
    
    [IgnoreDataMember]
    public IdentityRefWithVote[]? Reviewers { get; set; }

    public DateTime? QualityReviewedAt { get; set; }
    
    public DateTime? CodeReviewedAt { get; set; }
}