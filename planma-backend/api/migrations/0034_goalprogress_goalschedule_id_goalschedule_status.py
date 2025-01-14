# Generated by Django 5.1.3 on 2025-01-14 09:50

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0033_rename_classched_id_attendedclass_classsched_id_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='goalprogress',
            name='goalschedule_id',
            field=models.ForeignKey(db_column='schedule_id', default=1, on_delete=django.db.models.deletion.CASCADE, related_name='progresslogs', to='api.goalschedule'),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='goalschedule',
            name='status',
            field=models.CharField(choices=[('Pending', 'Pending'), ('Completed', 'Completed')], default='Pending', max_length=10),
        ),
    ]
