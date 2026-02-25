import 'dart:math';

class MotivationalMessages {
  static final Map<String, List<String>> _categoryMessages = {
    'Health': [
      'Your body is your temple. Take care of it!',
      'Small steps lead to big health changes.',
      'Today is a great day to prioritize your wellbeing!',
      'Health is wealth. Invest in yourself!',
      'Listen to your body. It knows what it needs.',
    ],
    'Fitness': [
      'Stronger than yesterday! Keep pushing!',
      'Every rep counts. You\'re getting better!',
      'Your only limit is you. Push harder!',
      'Sweat is just fat crying. You\'ve got this!',
      'Fitness is a journey, not a destination.',
    ],
    'Productivity': [
      'Make today count! You\'re capable of amazing things.',
      'Focus on progress, not perfection.',
      'One step at a time leads to great achievements.',
      'Your time is valuable. Make it matter!',
      'Small actions, big results.',
    ],
    'Learning': [
      'Knowledge is power. Keep learning!',
      'Every day is a chance to grow smarter.',
      'Your brain is a muscle. Exercise it!',
      'Learning is the key to success.',
      'Today\'s effort is tomorrow\'s success.',
    ],
    'Mindfulness': [
      'Be present. This moment is all you have.',
      'Breathe. You\'ve got this.',
      'Inner peace starts with a single breath.',
      'Take a moment to appreciate the now.',
      'Your mind deserves some quiet time.',
    ],
    'Social': [
      'Connection brings joy. Reach out today!',
      'Relationships need nurturing. Make time!',
      'Your tribe is waiting. Connect with them!',
      'Spread positivity. Make someone\'s day!',
      'Alone we can do so little, together we can do so much.',
    ],
    'Creativity': [
      'Create something beautiful today!',
      'Your imagination is limitless. Use it!',
      'Art is a way to express your soul.',
      'Every artist was once an amateur.',
      'Don\'t think. Just create!',
    ],
    'Finance': [
      'Financial freedom starts with small steps.',
      'Your future self will thank you.',
      'Save today, thrive tomorrow.',
      'Smart money habits create wealth.',
      'Financial wisdom is freedom.',
    ],
    'Reading': [
      'A book can change your life. Open one today!',
      'Reading feeds the mind.',
      'Every page is a new adventure.',
      'Knowledge awaits you in every book.',
      'Readers are leaders. Keep reading!',
    ],
    'Writing': [
      'Your words have power. Write your story!',
      'Start writing. Perfection comes later.',
      'Every word counts. Keep going!',
      'Your thoughts deserve to be written.',
      'Writing is thinking on paper.',
    ],
    'Other': [
      'You\'re doing great! Keep it up!',
      'Consistency is key. You\'re on the right track!',
      'Your habits shape your future. Make them count!',
      'Believe in yourself. You can do this!',
      'Great things never come from comfort zones.',
    ],
  };

  static String getMessage(String category, String habitName) {
    final messages = _categoryMessages[category] ?? _categoryMessages['Other']!;
    final message = messages[Random().nextInt(messages.length)];
    return '$message\n\n📌 $habitName';
  }

  static String getTitle(String category) {
    final titles = {
      'Health': 'Health Check!',
      'Fitness': 'Time to Move!',
      'Productivity': 'Let\'s Get Things Done!',
      'Learning': 'Learn & Grow!',
      'Mindfulness': 'Pause & Reflect',
      'Social': 'Time to Connect!',
      'Creativity': 'Create Something Amazing!',
      'Finance': 'Smart Money Move!',
      'Reading': 'Time to Read!',
      'Writing': 'Express Yourself!',
      'Other': 'Habit Reminder',
    };
    return titles[category] ?? 'Habit Reminder';
  }
}
