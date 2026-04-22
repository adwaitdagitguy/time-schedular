package com.meetingscheduler.algorithm;

import com.meetingscheduler.entity.Availability;
import com.meetingscheduler.entity.Meeting;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ScheduleOptimizerTest {

    private final ScheduleOptimizer optimizer = new ScheduleOptimizer();

    @Test
    void optimizeSchedule_schedulesHigherPriorityMeetingFirstWhenInputsAreEqual() {
        LocalDateTime base = LocalDateTime.now().plusDays(1).withHour(9).withMinute(0).withSecond(0).withNano(0);

        Meeting highPriority = createMeeting("High Priority", 10, 60, base.plusDays(1));
        Meeting lowPriority = createMeeting("Low Priority", 3, 60, base.plusDays(1));
        Availability availability = createAvailability(base, base.plusHours(3));

        ScheduleOptimizer.OptimizedScheduleResult result =
                optimizer.optimizeSchedule(List.of(lowPriority, highPriority), List.of(availability));

        assertEquals(2, result.getScheduledMeetings().size());
        assertEquals("High Priority", result.getScheduledMeetings().get(0).getMeeting().getTitle());
    }

    @Test
    void optimizeSchedule_skipsMeetingIfNoSlotBeforeDeadline() {
        LocalDateTime base = LocalDateTime.now().plusDays(1).withHour(9).withMinute(0).withSecond(0).withNano(0);

        Meeting expiredWindowMeeting = createMeeting("Expired Window", 8, 60, base.minusHours(2));
        Availability availability = createAvailability(base, base.plusHours(2));

        ScheduleOptimizer.OptimizedScheduleResult result =
                optimizer.optimizeSchedule(List.of(expiredWindowMeeting), List.of(availability));

        assertTrue(result.getScheduledMeetings().isEmpty());
        assertEquals(0.0, result.getOptimizationScore());
    }

    private Meeting createMeeting(String title, int priority, int durationMinutes, LocalDateTime deadline) {
        Meeting meeting = new Meeting();
        meeting.setTitle(title);
        meeting.setPriority(priority);
        meeting.setDurationMinutes(durationMinutes);
        meeting.setDeadline(deadline);
        meeting.setStatus(Meeting.MeetingStatus.pending);
        return meeting;
    }

    private Availability createAvailability(LocalDateTime start, LocalDateTime end) {
        Availability availability = new Availability();
        availability.setStartTime(start);
        availability.setEndTime(end);
        return availability;
    }
}
