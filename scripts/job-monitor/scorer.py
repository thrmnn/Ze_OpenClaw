"""
Job Scoring System

Scores validated job postings 0-100 based on:
- Role relevance (30 points)
- Experience fit (25 points)
- Tech stack match (25 points)
- Remote clarity (10 points)
- Company quality (10 points)

Threshold: Only report jobs with score ≥70
"""

import re
from typing import Dict, List, Tuple
from dataclasses import dataclass


@dataclass
class ScoreBreakdown:
    """Detailed score breakdown"""
    total: int  # 0-100
    role_relevance: int  # 0-30
    experience_fit: int  # 0-25
    tech_match: int  # 0-25
    remote_clarity: int  # 0-10
    company_quality: int  # 0-10
    explanation: List[str]  # Human-readable reasons


class JobScorer:
    """
    Scores job postings on 0-100 scale with detailed breakdown
    """
    
    # Role relevance scores (out of 30)
    ROLE_SCORES = {
        'ml engineer': 30,
        'machine learning engineer': 30,
        'applied ml': 30,
        'applied machine learning': 30,
        'ai engineer': 28,
        'artificial intelligence engineer': 28,
        'robotics engineer': 30,
        'robotics software engineer': 30,
        'computer vision engineer': 28,
        'perception engineer': 27,
        'autonomy engineer': 27,
        'data scientist': 20,  # Lower, often more analytics-focused
        'software engineer': 15,  # Generic, may not be ML-focused
    }
    
    # High-value tech keywords (5 points each)
    HIGH_VALUE_TECH = {
        'pytorch': 5,
        'tensorflow': 5,
        'jax': 5,
        'ros': 5,
        'ros2': 5,
    }
    
    # Medium-value tech keywords (3 points each)
    MEDIUM_VALUE_TECH = {
        'python': 3,
        'computer vision': 3,
        'slam': 3,
        'opencv': 3,
        'docker': 3,
        'linux': 3,
        'reinforcement learning': 3,
        'rl': 3,
        'kubernetes': 3,
        'cv': 2,  # Ambiguous, lower weight
    }
    
    # Remote clarity keywords
    REMOTE_KEYWORDS = {
        'fully remote': 10,
        '100% remote': 10,
        'remote-first': 8,
        'work from anywhere': 8,
        'distributed team': 7,
        'remote ok': 5,
        'remote': 3,  # Generic mention
    }
    
    # Company quality indicators
    COMPANY_INDICATORS = {
        'funded': 3,
        'series a': 2,
        'series b': 3,
        'series c': 3,
        'public company': 4,
        'well-funded': 3,
        'venture-backed': 2,
    }
    
    def score(self, job: Dict) -> ScoreBreakdown:
        """
        Score a job posting
        
        Args:
            job: Job data dict with keys:
                - title: str
                - description: str
                - company: str
                - location: str
                - experience_level: str (optional)
                - company_description: str (optional)
                - salary_range: str (optional)
        
        Returns:
            ScoreBreakdown with total and component scores
        """
        explanation = []
        
        # 1. Role Relevance (30 points)
        role_score, role_reasons = self._score_role_relevance(job)
        explanation.extend(role_reasons)
        
        # 2. Experience Fit (25 points)
        exp_score, exp_reasons = self._score_experience_fit(job)
        explanation.extend(exp_reasons)
        
        # 3. Tech Stack Match (25 points)
        tech_score, tech_reasons = self._score_tech_match(job)
        explanation.extend(tech_reasons)
        
        # 4. Remote Clarity (10 points)
        remote_score, remote_reasons = self._score_remote_clarity(job)
        explanation.extend(remote_reasons)
        
        # 5. Company Quality (10 points)
        company_score, company_reasons = self._score_company_quality(job)
        explanation.extend(company_reasons)
        
        total = role_score + exp_score + tech_score + remote_score + company_score
        
        return ScoreBreakdown(
            total=total,
            role_relevance=role_score,
            experience_fit=exp_score,
            tech_match=tech_score,
            remote_clarity=remote_score,
            company_quality=company_score,
            explanation=explanation
        )
    
    def _score_role_relevance(self, job: Dict) -> Tuple[int, List[str]]:
        """Score role relevance (0-30 points)"""
        title = job.get('title', '').lower()
        description = job.get('description', '').lower()
        
        reasons = []
        score = 0
        
        # Check title for role matches
        best_match = None
        best_score = 0
        
        for role, points in self.ROLE_SCORES.items():
            if role in title:
                if points > best_score:
                    best_match = role
                    best_score = points
        
        if best_match:
            score = best_score
            reasons.append(f"Role: {best_match.title()} ({score}/30)")
        else:
            # Check description if title doesn't match
            for role, points in self.ROLE_SCORES.items():
                if role in description:
                    score = max(score, int(points * 0.7))  # 70% of points if only in description
                    reasons.append(f"Role: {role.title()} mentioned in description ({score}/30)")
                    break
        
        if score == 0:
            score = 10  # Default for unrecognized but technical roles
            reasons.append(f"Role: Generic technical role ({score}/30)")
        
        return score, reasons
    
    def _score_experience_fit(self, job: Dict) -> Tuple[int, List[str]]:
        """Score experience fit (0-25 points)"""
        title = job.get('title', '').lower()
        description = job.get('description', '').lower()
        experience_level = job.get('experience_level', '').lower()
        
        combined_text = f"{title} {description} {experience_level}"
        reasons = []
        
        # Check for explicit entry/junior level
        if any(keyword in combined_text for keyword in ['entry', 'junior', 'early career', 'new grad']):
            reasons.append("Experience: Entry-level (25/25)")
            return 25, reasons
        
        # Check for years of experience mentioned
        years_match = re.search(r'(\d+)\s*[-–]\s*(\d+)\s*years?', description)
        if years_match:
            min_years = int(years_match.group(1))
            max_years = int(years_match.group(2))
            
            if max_years <= 2:
                reasons.append(f"Experience: {min_years}-{max_years} years (25/25)")
                return 25, reasons
            elif max_years <= 5:
                score = 20
                reasons.append(f"Experience: {min_years}-{max_years} years ({score}/25)")
                return score, reasons
            else:
                score = 10
                reasons.append(f"Experience: {min_years}-{max_years} years ({score}/25)")
                return score, reasons
        
        # Check for single year mention
        single_year = re.search(r'(\d+)\+?\s*years?', description)
        if single_year:
            years = int(single_year.group(1))
            if years <= 2:
                score = 25
            elif years <= 5:
                score = 20
            else:
                score = 5
            reasons.append(f"Experience: {years}+ years ({score}/25)")
            return score, reasons
        
        # Default: assume mid-level if not specified
        score = 18
        reasons.append(f"Experience: Not specified, assumed mid-level ({score}/25)")
        return score, reasons
    
    def _score_tech_match(self, job: Dict) -> Tuple[int, List[str]]:
        """Score tech stack match (0-25 points)"""
        description = job.get('description', '').lower()
        title = job.get('title', '').lower()
        
        combined_text = f"{title} {description}"
        reasons = []
        score = 0
        matches = []
        
        # Check high-value keywords
        for tech, points in self.HIGH_VALUE_TECH.items():
            if tech in combined_text:
                score += points
                matches.append(tech.upper())
        
        # Check medium-value keywords
        for tech, points in self.MEDIUM_VALUE_TECH.items():
            if tech in combined_text:
                score += points
                matches.append(tech.title())
        
        # Cap at 25 points
        score = min(score, 25)
        
        if matches:
            reasons.append(f"Tech Stack: {', '.join(matches[:6])} ({score}/25)")
        else:
            reasons.append(f"Tech Stack: No strong matches ({score}/25)")
        
        return score, reasons
    
    def _score_remote_clarity(self, job: Dict) -> Tuple[int, List[str]]:
        """Score remote clarity (0-10 points)"""
        title = job.get('title', '').lower()
        description = job.get('description', '').lower()
        location = job.get('location', '').lower()
        
        combined_text = f"{title} {description} {location}"
        reasons = []
        score = 0
        
        # Find best matching remote keyword
        best_match = None
        best_score = 0
        
        for keyword, points in self.REMOTE_KEYWORDS.items():
            if keyword in combined_text:
                if points > best_score:
                    best_match = keyword
                    best_score = points
        
        if best_match:
            score = best_score
            reasons.append(f"Remote: '{best_match}' ({score}/10)")
        else:
            score = 0
            reasons.append(f"Remote: Unclear ({score}/10)")
        
        return score, reasons
    
    def _score_company_quality(self, job: Dict) -> Tuple[int, List[str]]:
        """Score company quality (0-10 points)"""
        company = job.get('company', '').lower()
        company_description = job.get('company_description', '').lower()
        description = job.get('description', '').lower()
        
        combined_text = f"{company} {company_description} {description}"
        reasons = []
        score = 5  # Default baseline
        
        # Check for funding/quality indicators
        indicator_matches = []
        for indicator, points in self.COMPANY_INDICATORS.items():
            if indicator in combined_text:
                score += points
                indicator_matches.append(indicator)
        
        # Cap at 10 points
        score = min(score, 10)
        
        if indicator_matches:
            reasons.append(f"Company: {', '.join(indicator_matches)} ({score}/10)")
        else:
            reasons.append(f"Company: {company.title()} ({score}/10)")
        
        return score, reasons


def score_job(job: Dict, threshold: int = 70) -> Tuple[ScoreBreakdown, bool]:
    """
    Score a job and check if it meets threshold
    
    Args:
        job: Job data dictionary
        threshold: Minimum score to pass (default 70)
    
    Returns:
        (ScoreBreakdown, meets_threshold: bool)
    """
    scorer = JobScorer()
    breakdown = scorer.score(job)
    meets_threshold = breakdown.total >= threshold
    return breakdown, meets_threshold


def format_score_report(job: Dict, breakdown: ScoreBreakdown) -> str:
    """
    Format a human-readable score report
    
    Args:
        job: Job data dictionary
        breakdown: ScoreBreakdown from scoring
    
    Returns:
        Formatted report string
    """
    lines = []
    lines.append("=" * 70)
    lines.append(f"{job.get('company', 'Unknown')} | {job.get('title', 'Unknown')}")
    lines.append(f"Match Score: {breakdown.total}/100")
    lines.append("=" * 70)
    
    # Score breakdown
    lines.append("\nScore Breakdown:")
    lines.append(f"  Role Relevance:   {breakdown.role_relevance}/30")
    lines.append(f"  Experience Fit:   {breakdown.experience_fit}/25")
    lines.append(f"  Tech Stack:       {breakdown.tech_match}/25")
    lines.append(f"  Remote Clarity:   {breakdown.remote_clarity}/10")
    lines.append(f"  Company Quality:  {breakdown.company_quality}/10")
    
    # Explanation
    lines.append("\nDetails:")
    for reason in breakdown.explanation:
        lines.append(f"  • {reason}")
    
    # Link
    if job.get('url'):
        lines.append(f"\nApplication: {job['url']}")
    
    return "\n".join(lines)


if __name__ == "__main__":
    # Test with sample jobs
    test_jobs = [
        {
            'title': 'Machine Learning Engineer',
            'description': '''
            We're seeking an ML Engineer (1-3 years experience) for our robotics team.
            
            Requirements:
            - Python, PyTorch, computer vision
            - ROS2 experience preferred
            - Fully remote position
            
            We're a well-funded Series B startup building autonomous robots.
            ''',
            'company': 'RoboTech Inc',
            'location': 'Remote',
            'url': 'https://example.com/job/1'
        },
        {
            'title': 'AI Engineer - Computer Vision',
            'description': '''
            Looking for an early-career AI engineer to work on CV systems.
            
            Tech: Python, TensorFlow, OpenCV, Docker
            Remote-first company.
            ''',
            'company': 'VisionAI',
            'location': 'Remote',
            'url': 'https://example.com/job/2'
        },
        {
            'title': 'Software Engineer',
            'description': '''
            General software role. Some Python experience needed.
            Office-based with occasional remote work.
            ''',
            'company': 'SomeCorp',
            'location': 'San Francisco',
            'url': 'https://example.com/job/3'
        }
    ]
    
    print("Testing Job Scorer\n")
    
    for i, job in enumerate(test_jobs, 1):
        breakdown, passes = score_job(job, threshold=70)
        print(format_score_report(job, breakdown))
        print(f"\n{'✓ PASSES' if passes else '✗ DOES NOT PASS'} threshold (≥70)")
        print("\n" + "="*70 + "\n")
