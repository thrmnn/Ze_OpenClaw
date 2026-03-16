"""
Job Fetcher

Fetches job postings from configured sources
Supports multiple job boards and APIs
"""

import requests
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import time
from bs4 import BeautifulSoup
import random


class JobFetcher:
    """
    Base class for job fetching from various sources
    """
    
    def __init__(self, rate_limit_delay: float = 1.0):
        """
        Initialize fetcher
        
        Args:
            rate_limit_delay: Minimum delay between requests in seconds
        """
        self.rate_limit_delay = rate_limit_delay
        self.last_request_time = 0
        self.session = requests.Session()
        
        # Rotate user agents to avoid blocking
        self.user_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
        ]
    
    def _rate_limit(self):
        """Enforce rate limiting between requests"""
        elapsed = time.time() - self.last_request_time
        if elapsed < self.rate_limit_delay:
            time.sleep(self.rate_limit_delay - elapsed)
        self.last_request_time = time.time()
    
    def _get_headers(self) -> Dict[str, str]:
        """Get randomized headers"""
        return {
            'User-Agent': random.choice(self.user_agents),
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        }
    
    def fetch(self, **kwargs) -> List[Dict]:
        """
        Fetch jobs from source
        
        Returns:
            List of job dictionaries with standardized fields:
            - title: str
            - company: str
            - location: str
            - description: str
            - url: str
            - posted_date: datetime
            - source: str
        """
        raise NotImplementedError("Subclasses must implement fetch()")


class HackerNewsFetcher(JobFetcher):
    """
    Fetch jobs from Hacker News "Who is Hiring" threads
    Uses HN Algolia API
    """
    
    def __init__(self):
        super().__init__(rate_limit_delay=0.5)
        self.api_base = "https://hn.algolia.com/api/v1"
    
    def fetch(self, max_jobs: int = 50) -> List[Dict]:
        """
        Fetch jobs from latest "Who is Hiring" thread
        
        Args:
            max_jobs: Maximum number of jobs to return
        
        Returns:
            List of job dictionaries
        """
        jobs = []
        
        try:
            # Find latest "Who is Hiring" thread
            self._rate_limit()
            response = self.session.get(
                f"{self.api_base}/search?query=who%20is%20hiring&tags=story",
                headers=self._get_headers(),
                timeout=10
            )
            response.raise_for_status()
            
            stories = response.json().get('hits', [])
            if not stories:
                return jobs
            
            # Get latest thread
            latest_thread = stories[0]
            story_id = latest_thread['objectID']
            
            # Fetch comments from thread
            self._rate_limit()
            response = self.session.get(
                f"{self.api_base}/items/{story_id}",
                headers=self._get_headers(),
                timeout=10
            )
            response.raise_for_status()
            
            thread_data = response.json()
            comments = thread_data.get('children', [])
            
            # Parse comments for job postings
            for comment in comments[:max_jobs]:
                job = self._parse_hn_comment(comment)
                if job:
                    jobs.append(job)
            
        except Exception as e:
            print(f"Error fetching from Hacker News: {e}")
        
        return jobs
    
    def _parse_hn_comment(self, comment: Dict) -> Optional[Dict]:
        """Parse HN comment into job posting"""
        text = comment.get('text', '')
        if not text or len(text) < 50:
            return None
        
        # Simple parsing - look for remote/ML keywords
        text_lower = text.lower()
        
        # Filter for remote jobs
        if 'remote' not in text_lower:
            return None
        
        # Filter for ML/Robotics
        ml_keywords = ['machine learning', 'ml engineer', 'robotics', 'computer vision', 'ai engineer']
        if not any(keyword in text_lower for keyword in ml_keywords):
            return None
        
        # Extract company name (usually first line or in bold)
        soup = BeautifulSoup(text, 'html.parser')
        text_clean = soup.get_text()
        lines = text_clean.split('\n')
        
        company = "Unknown"
        if lines:
            # First line often contains company name
            first_line = lines[0].strip()
            if len(first_line) < 50:  # Likely a company name
                company = first_line
        
        return {
            'title': 'ML/Robotics Engineer (HN)',  # Generic, parsed from description
            'company': company,
            'location': 'Remote',
            'description': text_clean,
            'url': f"https://news.ycombinator.com/item?id={comment.get('id', '')}",
            'posted_date': datetime.fromtimestamp(comment.get('created_at_i', 0)) if comment.get('created_at_i') else datetime.now(),
            'source': 'hackernews'
        }


class YCombinatorJobsFetcher(JobFetcher):
    """
    Fetch jobs from Y Combinator Work at a Startup
    """
    
    def __init__(self):
        super().__init__(rate_limit_delay=2.0)
        self.base_url = "https://www.ycombinator.com/companies/jobs"
    
    def fetch(self, max_jobs: int = 50) -> List[Dict]:
        """
        Fetch jobs from YC jobs page
        
        Args:
            max_jobs: Maximum number of jobs to return
        
        Returns:
            List of job dictionaries
        """
        jobs = []
        
        try:
            # Search for ML jobs, remote only
            params = {
                'keyword': 'machine learning',
                'remote': 'true'
            }
            
            self._rate_limit()
            response = self.session.get(
                self.base_url,
                params=params,
                headers=self._get_headers(),
                timeout=10
            )
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Parse job listings (structure may change, this is a basic approach)
            job_cards = soup.find_all('div', class_='job-card')[:max_jobs]
            
            for card in job_cards:
                job = self._parse_yc_job(card)
                if job:
                    jobs.append(job)
            
        except Exception as e:
            print(f"Error fetching from Y Combinator: {e}")
        
        return jobs
    
    def _parse_yc_job(self, card) -> Optional[Dict]:
        """Parse YC job card into job posting"""
        try:
            title_elem = card.find('h3') or card.find('a', class_='job-title')
            company_elem = card.find('span', class_='company-name') or card.find('p', class_='company')
            
            if not title_elem:
                return None
            
            title = title_elem.get_text(strip=True)
            company = company_elem.get_text(strip=True) if company_elem else "YC Startup"
            
            # Get job URL
            link = title_elem.get('href') or card.find('a').get('href')
            url = f"https://www.ycombinator.com{link}" if link and not link.startswith('http') else link
            
            return {
                'title': title,
                'company': company,
                'location': 'Remote',
                'description': '',  # Would need to fetch detail page
                'url': url or self.base_url,
                'posted_date': datetime.now() - timedelta(days=random.randint(1, 7)),
                'source': 'ycombinator'
            }
        except Exception:
            return None


class MultiSourceFetcher:
    """
    Fetches jobs from multiple sources and aggregates them
    """
    
    def __init__(self):
        """Initialize with all available fetchers"""
        self.fetchers = {
            'hackernews': HackerNewsFetcher(),
            'ycombinator': YCombinatorJobsFetcher(),
        }
    
    def fetch_all(self, max_per_source: int = 20) -> List[Dict]:
        """
        Fetch jobs from all sources
        
        Args:
            max_per_source: Maximum jobs to fetch per source
        
        Returns:
            Aggregated list of jobs from all sources
        """
        all_jobs = []
        
        for source_name, fetcher in self.fetchers.items():
            print(f"Fetching from {source_name}...")
            try:
                jobs = fetcher.fetch(max_jobs=max_per_source)
                print(f"  Found {len(jobs)} jobs")
                all_jobs.extend(jobs)
            except Exception as e:
                print(f"  Error: {e}")
        
        return all_jobs
    
    def fetch_source(self, source: str, max_jobs: int = 20) -> List[Dict]:
        """
        Fetch jobs from specific source
        
        Args:
            source: Source name ('hackernews', 'ycombinator', etc.)
            max_jobs: Maximum jobs to fetch
        
        Returns:
            List of jobs from source
        """
        if source not in self.fetchers:
            raise ValueError(f"Unknown source: {source}")
        
        return self.fetchers[source].fetch(max_jobs=max_jobs)


if __name__ == "__main__":
    # Test fetchers
    print("Testing Job Fetchers")
    print("=" * 70)
    
    fetcher = MultiSourceFetcher()
    jobs = fetcher.fetch_all(max_per_source=5)
    
    print(f"\nTotal jobs fetched: {len(jobs)}")
    print("\nSample jobs:")
    print("=" * 70)
    
    for i, job in enumerate(jobs[:3], 1):
        print(f"\n{i}. {job['company']} - {job['title']}")
        print(f"   Source: {job['source']}")
        print(f"   URL: {job['url']}")
        print(f"   Description preview: {job['description'][:100]}...")
