// Supabase Edge Function: schedule-tasks
// Shared scheduling algorithm called by both web and iOS clients.
// Ported from src/lib/scheduling/

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ============================================================
// Types
// ============================================================

interface Project {
  id: string;
  name: string;
  priority: number;
  type: "personal" | "professional";
  weekend_enabled: boolean;
  deadline: string;
}

interface Task {
  id: string;
  name: string;
  effort_points: number;
  milestone_id: string | null;
  project_id: string;
  status: string;
  scheduled_date: string | null;
  sort_order: number;
}

interface TaskDependency {
  task_id: string;
  depends_on_task_id: string;
}

interface Milestone {
  id: string;
  name: string;
  project_id: string;
  target_date: string | null;
  sort_order: number;
}

interface ScheduleResult {
  scheduledTasks: Array<{ taskId: string; scheduledDate: string }>;
  conflicts: Array<{
    projectId: string;
    type: string;
    description: string;
    suggestedAction?: string;
  }>;
}

interface AvailabilityMap {
  [date: string]: number;
}

// ============================================================
// Cycle Calculator
// ============================================================

function getCycleDay(dateStr: string, day1Date: string, cycleLength: number): number {
  const target = new Date(dateStr);
  const start = new Date(day1Date);
  const diffTime = target.getTime() - start.getTime();
  const daysSinceStart = Math.floor(diffTime / (1000 * 60 * 60 * 24));

  if (daysSinceStart < 0) {
    const cyclesBack = Math.ceil(Math.abs(daysSinceStart) / cycleLength);
    const adjustedDays = daysSinceStart + cyclesBack * cycleLength;
    const cycleDay = (adjustedDays % cycleLength) + 1;
    return cycleDay === 0 ? cycleLength : cycleDay;
  }

  return (daysSinceStart % cycleLength) + 1;
}

function getDefaultEffortForCycleDay(cycleDay: number): number {
  if (cycleDay === 1) return 0;
  if (cycleDay === 2) return 2;
  if (cycleDay >= 3 && cycleDay <= 5) return 4;
  if (cycleDay >= 6 && cycleDay <= 10) return 8;
  if (cycleDay >= 11 && cycleDay <= 12) return 12;
  if (cycleDay >= 13 && cycleDay <= 15) return 15;
  if (cycleDay >= 16 && cycleDay <= 20) return 12;
  if (cycleDay >= 21 && cycleDay <= 23) return 10;
  if (cycleDay >= 24 && cycleDay <= 35) return 5;
  return 5;
}

// ============================================================
// Dependency Resolver (Kahn's Algorithm)
// ============================================================

function topologicalSort(tasks: Task[], dependencies: TaskDependency[]): Task[] | null {
  const adjList = new Map<string, string[]>();
  const inDegree = new Map<string, number>();

  tasks.forEach((task) => {
    adjList.set(task.id, []);
    inDegree.set(task.id, 0);
  });

  dependencies.forEach((dep) => {
    const from = dep.depends_on_task_id;
    const to = dep.task_id;
    if (adjList.has(from) && adjList.has(to)) {
      adjList.get(from)!.push(to);
      inDegree.set(to, (inDegree.get(to) || 0) + 1);
    }
  });

  const queue: string[] = [];
  tasks.forEach((task) => {
    if (inDegree.get(task.id) === 0) queue.push(task.id);
  });

  const sorted: Task[] = [];
  const taskMap = new Map(tasks.map((t) => [t.id, t]));

  while (queue.length > 0) {
    const taskId = queue.shift()!;
    const task = taskMap.get(taskId);
    if (task) sorted.push(task);

    (adjList.get(taskId) || []).forEach((neighborId) => {
      const degree = inDegree.get(neighborId)! - 1;
      inDegree.set(neighborId, degree);
      if (degree === 0) queue.push(neighborId);
    });
  }

  return sorted.length === tasks.length ? sorted : null;
}

// ============================================================
// Effort Allocator
// ============================================================

function formatDate(date: Date): string {
  return date.toISOString().split("T")[0];
}

function addDays(dateStr: string, days: number): string {
  const d = new Date(dateStr);
  d.setDate(d.getDate() + days);
  return formatDate(d);
}

function isWeekend(dateStr: string): boolean {
  const d = new Date(dateStr);
  const day = d.getDay();
  return day === 0 || day === 6;
}

function buildAvailabilityMap(
  day1Date: string,
  cycleLength: number,
  effortPointsMap: Map<number, number>,
  existingTasks: Task[]
): AvailabilityMap {
  const availability: AvailabilityMap = {};
  const today = formatDate(new Date());

  for (let i = 0; i < 365; i++) {
    const dateStr = addDays(today, i);
    const cycleDay = getCycleDay(dateStr, day1Date, cycleLength);
    availability[dateStr] = effortPointsMap.get(cycleDay) ?? getDefaultEffortForCycleDay(cycleDay);
  }

  existingTasks.forEach((task) => {
    if (task.scheduled_date && task.status !== "completed") {
      if (availability[task.scheduled_date] !== undefined) {
        availability[task.scheduled_date] = Math.max(0, availability[task.scheduled_date] - task.effort_points);
      }
    }
  });

  return availability;
}

function allocateTask(
  taskEffort: number,
  startDate: string,
  availabilityMap: AvailabilityMap,
  skipWeekends: boolean
): { dates: string[]; nextDate: string } | null {
  const scheduledDates: string[] = [];
  let remainingEffort = taskEffort;
  let currentDate = startDate;
  let attempts = 0;

  while (remainingEffort > 0 && attempts < 365) {
    attempts++;
    if (skipWeekends && isWeekend(currentDate)) {
      currentDate = addDays(currentDate, 1);
      continue;
    }

    const available = availabilityMap[currentDate] || 0;
    if (available > 0) {
      const usedEffort = Math.min(available, remainingEffort);
      scheduledDates.push(currentDate);
      availabilityMap[currentDate] = available - usedEffort;
      remainingEffort -= usedEffort;
    }
    currentDate = addDays(currentDate, 1);
  }

  if (remainingEffort > 0) return null;
  return { dates: scheduledDates, nextDate: currentDate };
}

function findNextAvailableDate(
  startDate: string,
  availabilityMap: AvailabilityMap,
  skipWeekends: boolean
): string {
  let currentDate = startDate;
  let attempts = 0;
  while (attempts < 365) {
    attempts++;
    if (skipWeekends && isWeekend(currentDate)) {
      currentDate = addDays(currentDate, 1);
      continue;
    }
    if ((availabilityMap[currentDate] || 0) > 0) return currentDate;
    currentDate = addDays(currentDate, 1);
  }
  return addDays(startDate, 365);
}

// ============================================================
// Scheduler
// ============================================================

function scheduleProject(
  project: Project,
  tasks: Task[],
  milestones: Milestone[],
  dependencies: TaskDependency[],
  availabilityMap: AvailabilityMap
): ScheduleResult {
  const result: ScheduleResult = { scheduledTasks: [], conflicts: [] };

  const projectTasks = tasks.filter((t) => t.project_id === project.id && t.status !== "completed");
  if (projectTasks.length === 0) return result;

  const sortedTasks = topologicalSort(projectTasks, dependencies);
  if (!sortedTasks) {
    result.conflicts.push({
      projectId: project.id,
      type: "impossible_deadline",
      description: "Circular dependency detected in tasks",
      suggestedAction: "Remove circular dependencies between tasks",
    });
    return result;
  }

  const projectMilestones = milestones
    .filter((m) => m.project_id === project.id)
    .sort((a, b) => a.sort_order - b.sort_order);

  const skipWeekends = project.type === "professional" && !project.weekend_enabled;
  const today = formatDate(new Date());
  let currentDate = findNextAvailableDate(today, availabilityMap, skipWeekends);

  // Group tasks by milestone
  const tasksByMilestone = new Map<string | null, Task[]>();
  sortedTasks.forEach((task) => {
    const key = task.milestone_id;
    if (!tasksByMilestone.has(key)) tasksByMilestone.set(key, []);
    tasksByMilestone.get(key)!.push(task);
  });

  // Schedule milestone tasks first, then unassigned
  for (const milestone of projectMilestones) {
    const milestoneTasks = tasksByMilestone.get(milestone.id) || [];
    for (const task of milestoneTasks) {
      const allocation = allocateTask(task.effort_points, currentDate, availabilityMap, skipWeekends);
      if (!allocation) {
        result.conflicts.push({
          projectId: project.id,
          type: "impossible_deadline",
          description: `Cannot schedule task "${task.name}" within available timeframe`,
          suggestedAction: "Consider extending the deadline or reducing scope",
        });
        continue;
      }
      result.scheduledTasks.push({ taskId: task.id, scheduledDate: allocation.dates[0] });
      currentDate = allocation.nextDate;
    }
  }

  // Schedule unassigned tasks
  const unassignedTasks = tasksByMilestone.get(null) || [];
  for (const task of unassignedTasks) {
    const allocation = allocateTask(task.effort_points, currentDate, availabilityMap, skipWeekends);
    if (!allocation) {
      result.conflicts.push({
        projectId: project.id,
        type: "impossible_deadline",
        description: `Cannot schedule task "${task.name}" within available timeframe`,
        suggestedAction: "Consider extending the deadline or reducing scope",
      });
      continue;
    }
    result.scheduledTasks.push({ taskId: task.id, scheduledDate: allocation.dates[0] });
    currentDate = allocation.nextDate;
  }

  // Check deadline
  const lastTask = result.scheduledTasks[result.scheduledTasks.length - 1];
  if (lastTask && project.deadline) {
    const lastDate = new Date(lastTask.scheduledDate);
    const deadlineDate = new Date(project.deadline);
    if (lastDate > deadlineDate) {
      const daysDiff = Math.ceil((lastDate.getTime() - deadlineDate.getTime()) / (1000 * 60 * 60 * 24));
      result.conflicts.push({
        projectId: project.id,
        type: "impossible_deadline",
        description: `Project will complete ${daysDiff} days after deadline`,
        suggestedAction: `Consider extending deadline to ${formatDate(lastDate)} or reducing scope`,
      });
    }
  }

  return result;
}

// ============================================================
// Edge Function Handler
// ============================================================

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { userId } = await req.json();

    // Fetch all user data
    const [
      { data: projects },
      { data: cycles },
      { data: allTasks },
      { data: milestones },
      { data: taskDeps },
      { data: effortPoints },
    ] = await Promise.all([
      supabaseClient.from("projects").select("*").eq("user_id", userId).eq("status", "active"),
      supabaseClient.from("cycles").select("*").eq("user_id", userId).limit(1),
      supabaseClient.from("tasks").select("*").in_(
        "project_id",
        (await supabaseClient.from("projects").select("id").eq("user_id", userId)).data?.map((p: any) => p.id) || []
      ),
      supabaseClient.from("milestones").select("*"),
      supabaseClient.from("task_dependencies").select("*"),
      supabaseClient.from("cycle_effort_points").select("*"),
    ]);

    if (!cycles || cycles.length === 0) {
      return new Response(
        JSON.stringify({ scheduledTasks: [], conflicts: [{ projectId: "", type: "impossible_deadline", description: "No cycle configured" }] }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const cycle = cycles[0];
    const effortPointsMap = new Map<number, number>();
    (effortPoints || [])
      .filter((ep: any) => ep.cycle_id === cycle.id)
      .forEach((ep: any) => effortPointsMap.set(ep.day_number, ep.effort_points));

    // Build availability map
    const availabilityMap = buildAvailabilityMap(
      cycle.day1_date,
      cycle.length,
      effortPointsMap,
      allTasks || []
    );

    // Sort projects by priority (descending) and schedule each
    const sortedProjects = [...(projects || [])].sort((a: any, b: any) => b.priority - a.priority);

    const finalResult: ScheduleResult = { scheduledTasks: [], conflicts: [] };

    for (const project of sortedProjects) {
      const projectResult = scheduleProject(
        project,
        allTasks || [],
        milestones || [],
        taskDeps || [],
        availabilityMap
      );
      finalResult.scheduledTasks.push(...projectResult.scheduledTasks);
      finalResult.conflicts.push(...projectResult.conflicts);
    }

    // Update tasks in database with scheduled dates
    for (const scheduled of finalResult.scheduledTasks) {
      await supabaseClient
        .from("tasks")
        .update({ scheduled_date: scheduled.scheduledDate, status: "scheduled" })
        .eq("id", scheduled.taskId);
    }

    // Save conflicts
    if (finalResult.conflicts.length > 0) {
      // Clear old unresolved conflicts for this user
      await supabaseClient
        .from("scheduling_conflicts")
        .delete()
        .eq("user_id", userId)
        .eq("resolved", false);

      const conflictRows = finalResult.conflicts.map((c) => ({
        user_id: userId,
        project_id: c.projectId || null,
        type: c.type,
        description: c.description,
        suggestion: c.suggestedAction || null,
        severity: c.type === "impossible_deadline" ? "critical" : "warning",
      }));

      await supabaseClient.from("scheduling_conflicts").insert(conflictRows);
    }

    return new Response(JSON.stringify(finalResult), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
