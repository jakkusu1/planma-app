# Generated by Django 5.1.3 on 2024-12-09 12:26

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0022_alter_goals_goal_type_alter_goals_semester_id_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='goalschedule',
            name='scheduled_date',
            field=models.DateField(),
            preserve_default=False,
        ),
    ]