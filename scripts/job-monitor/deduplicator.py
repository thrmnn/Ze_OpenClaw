"""
Job Deduplication

Detects duplicate job postings across sources using:
- Content hashing
- Company + title + location matching
- URL comparison
"""

import hashlib
import re
from typing import Dict, List, Optional, Set, Tuple
from datetime import datetime
from dataclasses import dataclass


@dataclass
class JobFingerprint:
    """Unique identifier for a job posting"""
    content_hash: str
    company_normalized: str
    title_normalized: str
    location_normalized: str
    url_domain: str


class JobDeduplicator:
    """
    Detects and tracks duplicate job postings
    """
    
    def __init__(self):
        """Initialize deduplicator with in-memory tracking"""
        self.seen_hashes: Set[str] = set()
        self.seen_jobs: Dict[str, Dict] = {}
    
    def is_duplicate(self, job: Dict) -> Tuple[bool, Optional[str]]:
        """
        Check if job is a duplicate
        
        Args:
            job: Job data dictionary
        
        Returns:
            (is_duplicate: bool, reason: Optional[str])
        """
        fingerprint = self._generate_fingerprint(job)
        
        # Check exact content hash
        if fingerprint.content_hash in self.seen_hashes:
            return True, "Exact duplicate (same content hash)"
        
        # Check fuzzy match (company + title + location)
        fuzzy_key = f"{fingerprint.company_normalized}:{fingerprint.title_normalized}:{fingerprint.location_normalized}"
        
        if fuzzy_key in self.seen_jobs:
            existing = self.seen_jobs[fuzzy_key]
            
            # Check if it's the same job or an update
            if existing.get('url') == job.get('url'):
                return True, "Same job, same URL"
            
            # Check if from different source but same role
            if self._similarity_score(existing, job) > 0.85:
                return True, f"Cross-posted from {existing.get('source', 'unknown')}"
        
        # Not a duplicate - store fingerprint
        self.seen_hashes.add(fingerprint.content_hash)
        self.seen_jobs[fuzzy_key] = job
        
        return False, None
    
    def _generate_fingerprint(self, job: Dict) -> JobFingerprint:
        """Generate unique fingerprint for job"""
        # Normalize text
        company = self._normalize_text(job.get('company', ''))
        title = self._normalize_text(job.get('title', ''))
        location = self._normalize_text(job.get('location', ''))
        description = self._normalize_text(job.get('description', ''))
        
        # Create content hash
        content = f"{company}|{title}|{location}|{description[:500]}"
        content_hash = hashlib.sha256(content.encode()).hexdigest()[:16]
        
        # Extract URL domain
        url = job.get('url', '')
        url_domain = self._extract_domain(url)
        
        return JobFingerprint(
            content_hash=content_hash,
            company_normalized=company,
            title_normalized=title,
            location_normalized=location,
            url_domain=url_domain
        )
    
    def _normalize_text(self, text: str) -> str:
        """Normalize text for comparison"""
        if not text:
            return ""
        
        # Lowercase
        text = text.lower()
        
        # Remove extra whitespace
        text = ' '.join(text.split())
        
        # Remove punctuation
        text = re.sub(r'[^\w\s]', '', text)
        
        # Remove common suffixes (Inc, LLC, etc.)
        text = re.sub(r'\b(inc|llc|ltd|corp|corporation|company)\b', '', text)
        
        return text.strip()
    
    def _extract_domain(self, url: str) -> str:
        """Extract domain from URL"""
        if not url:
            return ""
        
        # Simple domain extraction
        match = re.search(r'https?://([^/]+)', url)
        if match:
            domain = match.group(1)
            # Remove www.
            domain = re.sub(r'^www\.', '', domain)
            return domain
        
        return ""
    
    def _similarity_score(self, job1: Dict, job2: Dict) -> float:
        """
        Calculate similarity between two jobs (0.0 - 1.0)
        
        Uses fuzzy matching on:
        - Company name
        - Job title
        - Location
        - Description (first 200 chars)
        """
        score = 0.0
        total_weight = 0.0
        
        # Company (weight: 0.3)
        company1 = self._normalize_text(job1.get('company', ''))
        company2 = self._normalize_text(job2.get('company', ''))
        if company1 and company2:
            score += 0.3 if company1 == company2 else 0.0
            total_weight += 0.3
        
        # Title (weight: 0.4)
        title1 = self._normalize_text(job1.get('title', ''))
        title2 = self._normalize_text(job2.get('title', ''))
        if title1 and title2:
            title_sim = self._word_overlap(title1, title2)
            score += 0.4 * title_sim
            total_weight += 0.4
        
        # Location (weight: 0.1)
        loc1 = self._normalize_text(job1.get('location', ''))
        loc2 = self._normalize_text(job2.get('location', ''))
        if loc1 and loc2:
            score += 0.1 if loc1 == loc2 else 0.0
            total_weight += 0.1
        
        # Description overlap (weight: 0.2)
        desc1 = self._normalize_text(job1.get('description', '')[:200])
        desc2 = self._normalize_text(job2.get('description', '')[:200])
        if desc1 and desc2:
            desc_sim = self._word_overlap(desc1, desc2)
            score += 0.2 * desc_sim
            total_weight += 0.2
        
        return score / total_weight if total_weight > 0 else 0.0
    
    def _word_overlap(self, text1: str, text2: str) -> float:
        """Calculate word overlap between two texts"""
        words1 = set(text1.split())
        words2 = set(text2.split())
        
        if not words1 or not words2:
            return 0.0
        
        intersection = words1 & words2
        union = words1 | words2
        
        return len(intersection) / len(union) if union else 0.0


class PersistentDeduplicator(JobDeduplicator):
    """
    Deduplicator with SQLite persistence
    
    Tracks jobs across runs and maintains history
    """
    
    def __init__(self, db_path: str = "data/job-monitor.db"):
        """
        Initialize with database connection
        
        Args:
            db_path: Path to SQLite database
        """
        super().__init__()
        self.db_path = db_path
        self._init_db()
        self._load_from_db()
    
    def _init_db(self):
        """Initialize database schema"""
        import sqlite3
        from pathlib import Path
        
        # Create data directory if needed
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS jobs (
                content_hash TEXT PRIMARY KEY,
                company TEXT,
                title TEXT,
                location TEXT,
                url TEXT,
                source TEXT,
                first_seen TEXT,
                last_seen TEXT,
                view_count INTEGER DEFAULT 1
            )
        ''')
        
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_company_title 
            ON jobs(company, title)
        ''')
        
        conn.commit()
        conn.close()
    
    def _load_from_db(self):
        """Load recent jobs from database"""
        import sqlite3
        from datetime import datetime, timedelta
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Load jobs from last 30 days
        cutoff = (datetime.now() - timedelta(days=30)).isoformat()
        
        cursor.execute('''
            SELECT content_hash, company, title, location, url, source
            FROM jobs
            WHERE last_seen > ?
        ''', (cutoff,))
        
        for row in cursor.fetchall():
            content_hash, company, title, location, url, source = row
            self.seen_hashes.add(content_hash)
            
            fuzzy_key = f"{self._normalize_text(company)}:{self._normalize_text(title)}:{self._normalize_text(location)}"
            self.seen_jobs[fuzzy_key] = {
                'company': company,
                'title': title,
                'location': location,
                'url': url,
                'source': source
            }
        
        conn.close()
    
    def mark_seen(self, job: Dict):
        """
        Mark job as seen in database
        
        Args:
            job: Job data dictionary
        """
        import sqlite3
        
        fingerprint = self._generate_fingerprint(job)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        now = datetime.now().isoformat()
        
        # Insert or update
        cursor.execute('''
            INSERT INTO jobs (content_hash, company, title, location, url, source, first_seen, last_seen)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(content_hash) DO UPDATE SET
                last_seen = ?,
                view_count = view_count + 1
        ''', (
            fingerprint.content_hash,
            job.get('company', ''),
            job.get('title', ''),
            job.get('location', ''),
            job.get('url', ''),
            job.get('source', ''),
            now,
            now,
            now
        ))
        
        conn.commit()
        conn.close()


if __name__ == "__main__":
    # Test deduplicator
    dedup = JobDeduplicator()
    
    job1 = {
        'company': 'TechCorp Inc.',
        'title': 'Machine Learning Engineer',
        'location': 'Remote',
        'description': 'We are looking for an ML engineer to join our team...',
        'url': 'https://techcorp.com/jobs/123',
        'source': 'indeed'
    }
    
    job2 = {
        'company': 'TechCorp',  # Slight variation
        'title': 'Machine Learning Engineer',
        'location': 'Remote',
        'description': 'We are looking for an ML engineer to join our team...',
        'url': 'https://linkedin.com/jobs/456',  # Different URL
        'source': 'linkedin'
    }
    
    job3 = {
        'company': 'RoboCorp',
        'title': 'Robotics Engineer',
        'location': 'Remote',
        'description': 'Seeking robotics engineer for autonomous systems...',
        'url': 'https://robocorp.com/jobs/789',
        'source': 'ycombinator'
    }
    
    # Test
    print("Testing Deduplicator")
    print("=" * 50)
    
    is_dup, reason = dedup.is_duplicate(job1)
    print(f"Job 1: {'Duplicate' if is_dup else 'New'} - {reason or 'First time seen'}")
    
    is_dup, reason = dedup.is_duplicate(job2)
    print(f"Job 2: {'Duplicate' if is_dup else 'New'} - {reason or 'First time seen'}")
    
    is_dup, reason = dedup.is_duplicate(job3)
    print(f"Job 3: {'Duplicate' if is_dup else 'New'} - {reason or 'First time seen'}")
    
    is_dup, reason = dedup.is_duplicate(job1)
    print(f"Job 1 (again): {'Duplicate' if is_dup else 'New'} - {reason or 'First time seen'}")
