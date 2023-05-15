using System.Text;
using Microsoft.TeamFoundation.Core.WebApi;
using Microsoft.TeamFoundation.SourceControl.WebApi;
using Microsoft.VisualStudio.Services.Common;
using Microsoft.VisualStudio.Services.WebApi;
using Oexenhave.AzureDevOpsFetch;
using ServiceStack.Text;

if (args.Length != 2)
{
    Console.WriteLine("Please provide tenant URL and PAT as parameters.");
    Console.WriteLine("Example:");
    Console.WriteLine("   Oexenhave.AzureDevOpsFetch.exe https://dev.azure.com/[tenantId] pgkxwdc7ikjm3jdvbiag6r7ylmbyxpahkty5ifr4mhls4tfpp7aa");
    Console.WriteLine("");
    Console.WriteLine("Generate a PAT from https://dev.azure6.com/{tenant}/_usersSettings/tokens");
    Console.WriteLine("Add access for \"Code (Read)\"");
}
else
{
    var collectionUri = args[0];
    var pat = args[1];

    // Connect to Azure DevOps Services
    var credentials = new VssBasicCredential(string.Empty, pat);
    var connection = new VssConnection(new Uri(collectionUri), credentials);

    // Get a GitHttpClient to talk to the Git endpoints
    using var gitClient = connection.GetClient<GitHttpClient>();
    var projectClient = connection.GetClient<ProjectHttpClient>();
    var projects = await projectClient.GetProjects();

    var pullRequestStats = new List<PullRequestStat>();

    foreach (var project in projects)
    {
        var projectRepos = await gitClient.GetRepositoriesAsync(project.Id);
        foreach (var repository in projectRepos)
        {
            int skip = 0;
            var pullRequests = await gitClient.GetPullRequestsAsync(project.Id, repository.Id,
                new GitPullRequestSearchCriteria { Status = PullRequestStatus.All });

            while (skip == 0 || pullRequestStats.Count > 0)
            {
                Console.WriteLine("[{0:O}] Processing {1}... ({2}/{3})", DateTime.Now, skip, project.Name,
                    repository.Name);

                if (pullRequests.Count == 0)
                {
                    break;
                }

                foreach (var pullRequest in pullRequests.Where(request =>
                             request.IsDraft == false && request.Status != PullRequestStatus.Abandoned))
                {
                    var pullRequestStat = new PullRequestStat
                    {
                        ProjectName = project.Name,
                        RepositoryName = repository.Name,
                        PullRequestId = pullRequest.PullRequestId,
                        Title = pullRequest.Title,
                        CreatedAt = pullRequest.CreationDate,
                        ClosedAt = pullRequest.ClosedDate,
                        Status = pullRequest.Status,
                        Reviewers = pullRequest.Reviewers,
                        Creator = pullRequest.CreatedBy.DisplayName
                    };

                    var threads =
                        await gitClient.GetThreadsAsync(project.Name, repository.Id, pullRequest.PullRequestId);
                    var reviewThreads =
                        threads.Where(thread =>
                                thread.Properties.ContainsKey("CodeReviewThreadType") &&
                                thread.Properties.ContainsValue("VoteUpdate"))
                            .OrderByDescending(thread => thread.PublishedDate).ToList();

                    var codeReviewedAt = reviewThreads.FirstOrDefault(thread =>
                        thread.Comments.First().Author.DisplayName == pullRequestStat.CodeReviewer)?.PublishedDate;
                    var qualityReviewedAt = reviewThreads.FirstOrDefault(thread =>
                        thread.Comments.First().Author.DisplayName == pullRequestStat.QualityReviewer)?.PublishedDate;

                    pullRequestStat.CodeReviewedAt = codeReviewedAt;
                    pullRequestStat.QualityReviewedAt = qualityReviewedAt;

                    pullRequestStats.Add(pullRequestStat);
                }

                skip += pullRequests.Count;
                pullRequests = await gitClient.GetPullRequestsAsync(project.Id, repository.Id,
                    new GitPullRequestSearchCriteria { Status = PullRequestStatus.All }, skip: skip);
            }
        }
    }

    File.WriteAllText("output.csv", CsvSerializer.SerializeToCsv(pullRequestStats), Encoding.UTF8);
}

Console.WriteLine("Press any key to close...");
Console.ReadKey();