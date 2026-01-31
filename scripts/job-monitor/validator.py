"""
Job Validation Engine

Validates job postings against defined rules to filter out:
- Stale postings (>30 days old)
- Spam/illegitimate companies
- Non-remote roles
- Senior/lead positions
- Missing required tech keywords
"""

import re
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
import requests
from urllib.parse import urlparse


@dataclass
class ValidationResult:
    """Result of validation with pass/fail and reasons"""
    is_valid: bool
    score: int  # 0-100
    reasons: List[str]  # Why it passed or failed
    warnings: List[str]  # Non-fatal issues


class JobValidator:
    """
    Validates job postings against quality and relevance criteria
    """
    
    # Keywords that indicate senior/lead positions (auto-reject)
    SENIOR_KEYWORDS = [
        'senior', 'staff', 'principal', 'lead', 'head of', 
        'director', 'manager', 'vp', 'vice president', 'chief',
        'sr.', 'sr ', 'senior-level'
    ]
    
    # Keywords that indicate research-only roles (auto-reject)
    RESEARCH_KEYWORDS = [
        'research scientist', 'research engineer', 'postdoc',
        'phd required', 'doctorate required', 'research-focused'
    ]
    
    # Required tech keywords (must have at least 2)
    REQUIRED_TECH = [
        'python', 'pytorch', 'tensorflow', 'jax',
        'ros', 'ros2', 'computer vision', 'slam', 
        'reinforcement learning', 'rl', 'opencv',
        'docker', 'linux', 'kubernetes', 'cv'
    ]
    
    # Remote keywords (positive signals)
    REMOTE_POSITIVE = [
        'fully remote', '100% remote', 'remote-first',
        'work from anywhere', 'distributed team', 'remote ok',
        'remote position', 'remote role'
    ]
    
    # On-site keywords (negative signals)
    ONSITE_NEGATIVE = [
        'on-site', 'onsite', 'office-based', 'in-office',
        'must be located in', 'relocation required',
        'hybrid required', 'must relocate'
    ]
    
    # Spam indicators
    SPAM_KEYWORDS = [
        'mlm', 'multi-level', 'commission only', 'pay to apply',
        'training program', 'bootcamp graduate', 'no experience needed',
        'work from home opportunity', 'be your own boss'
    ]
    
    def __init__(self, max_age_days: int = 30):
        """
        Initialize validator
        
        Args:
            max_age_days: Maximum age for job posting in days
        """
        self.max_age_days = max_age_days
    
    def validate(self, job: Dict) -> ValidationResult:
        """
        Validate a job posting
        
        Args:
            job: Job data dict with keys:
                - title: str
                - description: str
                - company: str
                - location: str
                - posted_date: datetime or str
                - url: str
                - experience_level: str (optional)
                - company_url: str (optional)
        
        Returns:
            ValidationResult with pass/fail and detailed reasons
        """
        reasons = []
        warnings = []
        is_valid = True
        
        # Rule 1: Check recency
        recency_valid, recency_reason = self._check_recency(job.get('posted_date'))
        if not recency_valid:
            is_valid = False
            reasons.append(recency_reason)
        
        # Rule 2: Check legitimacy
        legitimacy_valid, legitimacy_reason = self._check_legitimacy(job)
        if not legitimacy_valid:
            is_valid = False
            reasons.append(legitimacy_reason)
        elif legitimacy_reason:
            warnings.append(legitimacy_reason)
        
        # Rule 3: Check remote eligibility
        remote_valid, remote_reason = self._check_remote(job)
        if not remote_valid:
            is_valid = False
            reasons.append(remote_reason)
        elif remote_reason:
            warnings.append(remote_reason)
        
        # Rule 4: Check experience level
        exp_valid, exp_reason = self._check_experience(job)
        if not exp_valid:
            is_valid = False
            reasons.append(exp_reason)
        
        # Rule 5: Check tech requirements
        tech_valid, tech_reason, tech_count = self._check_tech_keywords(job)
        if not tech_valid:
            is_valid = False
            reasons.append(tech_reason)
        else:
            reasons.append(f"✓ Found {tech_count} required tech keywords")
        
        # Check for spam
        spam_check, spam_reason = self._check_spam(job)
        if not spam_check:
            is_valid = False
            reasons.append(spam_reason)
        
        # Calculate validation score (0-100)
        score = self._calculate_validation_score(
            recency_valid, legitimacy_valid, remote_valid, 
            exp_valid, tech_valid, tech_count, spam_check
        )
        
        if is_valid:
            reasons.insert(0, "✓ Passed all validation rules")
        
        return ValidationResult(
            is_valid=is_valid,
            score=score,
            reasons=reasons,
            warnings=warnings
        )
    
    def _check_recency(self, posted_date) -> Tuple[bool, str]:
        """Check if job is recent enough"""
        if not posted_date:
            return False, "❌ Missing posted date"
        
        # Convert to datetime if string
        if isinstance(posted_date, str):
            try:
                posted_date = datetime.fromisoformat(posted_date.replace('Z', '+00:00'))
            except:
                return False, f"❌ Invalid date format: {posted_date}"
        
        age = datetime.now(posted_date.tzinfo) - posted_date
        
        if age.days > self.max_age_days:
            return False, f"❌ Too old ({age.days} days, max {self.max_age_days})"
        
        return True, f"✓ Posted {age.days} days ago"
    
    def _check_legitimacy(self, job: Dict) -> Tuple[bool, Optional[str]]:
        """Check if company appears legitimate"""
        company = job.get('company', '').lower()
        description = job.get('description', '').lower()
        company_url = job.get('company_url', '')
        
        # Check for missing company name
        if not company or len(company) < 2:
            return False, "❌ Missing or invalid company name"
        
        # Check for spam indicators in company name
        spam_patterns = ['llc inc', 'consultancy', 'staffing', 'recruiting firm']
        if any(pattern in company for pattern in spam_patterns):
            return True, "⚠️  Company may be staffing/consultancy"
        
        # Check company URL if provided
        if company_url:
            try:
                domain = urlparse(company_url).netloc
                if not domain or len(domain) < 4:
                    return True, "⚠️  Suspicious company URL"
            except:
                return True, "⚠️  Invalid company URL format"
        
        return True, None
    
    def _check_remote(self, job: Dict) -> Tuple[bool, Optional[str]]:
        """Check remote eligibility"""
        title = job.get('title', '').lower()
        description = job.get('description', '').lower()
        location = job.get('location', '').lower()
        
        combined_text = f"{title} {description} {location}"
        
        # Check for positive remote signals
        remote_score = sum(1 for keyword in self.REMOTE_POSITIVE if keyword in combined_text)
        
        # Check for negative on-site signals
        onsite_score = sum(1 for keyword in self.ONSITE_NEGATIVE if keyword in combined_text)
        
        # Require explicit remote mention
        if remote_score == 0 and 'remote' not in combined_text:
            return False, "❌ No remote indication found"
        
        # Reject if strong on-site signals
        if onsite_score >= 2:
            return False, f"❌ On-site requirements detected ({onsite_score} signals)"
        
        # Warn if mixed signals
        if remote_score > 0 and onsite_score > 0:
            return True, f"⚠️  Mixed remote/on-site signals (remote:{remote_score}, onsite:{onsite_score})"
        
        return True, f"✓ Remote eligible (confidence: {remote_score} signals)"
    
    def _check_experience(self, job: Dict) -> Tuple[bool, str]:
        """Check experience level requirements"""
        title = job.get('title', '').lower()
        description = job.get('description', '').lower()
        experience_level = job.get('experience_level', '').lower()
        
        combined_text = f"{title} {description} {experience_level}"
        
        # Check for senior/lead keywords (auto-reject)
        for keyword in self.SENIOR_KEYWORDS:
            if keyword in title or keyword in experience_level:
                return False, f"❌ Senior/Lead position: '{keyword}' in title/level"
        
        # Check description for years of experience
        years_match = re.search(r'(\d+)\+?\s*years?\s*(of\s*)?experience', description)
        if years_match:
            years = int(years_match.group(1))
            if years > 5:
                return False, f"❌ Requires {years}+ years experience (max 5)"
        
        # Check for research-only roles
        for keyword in self.RESEARCH_KEYWORDS:
            if keyword in combined_text:
                return False, f"❌ Research-only role: '{keyword}' found"
        
        # Check for entry/junior level (positive signal)
        entry_keywords = ['entry', 'junior', 'early career', '0-2 years', '1-3 years']
        if any(keyword in combined_text for keyword in entry_keywords):
            return True, "✓ Entry/junior level role"
        
        return True, "✓ Experience level acceptable"
    
    def _check_tech_keywords(self, job: Dict) -> Tuple[bool, str, int]:
        """Check for required tech keywords"""
        description = job.get('description', '').lower()
        title = job.get('title', '').lower()
        
        combined_text = f"{title} {description}"
        
        # Count matching keywords
        matches = [tech for tech in self.REQUIRED_TECH if tech in combined_text]
        count = len(matches)
        
        if count < 2:
            return False, f"❌ Insufficient tech keywords ({count}/2 minimum): {matches}", count
        
        return True, f"✓ Tech stack match: {', '.join(matches[:5])}", count
    
    def _check_spam(self, job: Dict) -> Tuple[bool, str]:
        """Check for spam indicators"""
        title = job.get('title', '').lower()
        description = job.get('description', '').lower()
        
        combined_text = f"{title} {description}"
        
        for spam_keyword in self.SPAM_KEYWORDS:
            if spam_keyword in combined_text:
                return False, f"❌ Spam detected: '{spam_keyword}'"
        
        return True, "✓ No spam detected"
    
    def _calculate_validation_score(
        self, recency: bool, legitimacy: bool, remote: bool,
        experience: bool, tech: bool, tech_count: int, spam: bool
    ) -> int:
        """Calculate validation score 0-100"""
        score = 0
        
        if recency:
            score += 15
        if legitimacy:
            score += 20
        if remote:
            score += 20
        if experience:
            score += 20
        if tech:
            score += min(tech_count * 5, 20)  # Up to 20 points for tech
        if spam:
            score += 5
        
        return min(score, 100)


def validate_job(job: Dict) -> ValidationResult:
    """
    Convenience function to validate a single job
    
    Args:
        job: Job data dictionary
    
    Returns:
        ValidationResult
    """
    validator = JobValidator()
    return validator.validate(job)


if __name__ == "__main__":
    # Test with sample job
    test_job = {
        'title': 'Machine Learning Engineer',
        'description': '''
        We're looking for an ML Engineer to work on computer vision and robotics.
        
        Requirements:
        - 1-3 years experience with Python and PyTorch
        - Computer vision and ROS experience
        - Fully remote position
        
        Nice to have:
        - Docker and Linux experience
        ''',
        'company': 'TechCorp Inc',
        'location': 'Remote',
        'posted_date': datetime.now() - timedelta(days=5),
        'url': 'https://example.com/job/123',
        'company_url': 'https://techcorp.com'
    }
    
    result = validate_job(test_job)
    print(f"Valid: {result.is_valid}")
    print(f"Score: {result.score}/100")
    print("\nReasons:")
    for reason in result.reasons:
        print(f"  {reason}")
    if result.warnings:
        print("\nWarnings:")
        for warning in result.warnings:
            print(f"  {warning}")
