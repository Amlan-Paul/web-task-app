# WebTask Manager — Website Update & Task Management

Google Sheet-ভিত্তিক ওয়েবসাইট টাস্ক ও ডিপ্লয়মেন্ট আপডেট ম্যানেজমেন্ট ওয়েব অ্যাপ্লিকেশন।

## ফাইল তালিকা:
- `index.html`: সম্পূর্ণ ফ্রন্টএন্ড ওয়েব অ্যাপ (HTML, CSS/Tailwind, JavaScript, Chart.js)।
- `Code.gs`: Google Apps Script কোড যা Google Sheet-কে লাইভ REST API ডাটাবেসে পরিণত করে।

## গুগল শিট সেটআপ নির্দেশিকা:
1. আপনার Google Sheet ওপেন করুন: `Extensions` > `Apps Script` মেনুতে যান।
2. `Code.gs` ফাইলের কোড পেস্ট করুন এবং Save করুন।
3. ডানদিকের `Deploy` > `New deployment` চাপুন।
4. `Select type` হিসেবে `Web app` সিলেক্ট করে Access দিন `Anyone` এবং Deploy করুন।
5. প্রাপ্ত Web App URL টি অ্যাপ্লিকেশনের "শিট কনফিগারেশন" ট্যাবে যুক্ত করুন।
