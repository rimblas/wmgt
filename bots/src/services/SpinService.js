import { config } from '../config/config.js';
import { readFile } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { EmbedBuilder } from 'discord.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const COURSES_FILE_PATH = path.join(__dirname, '..', '..', 'data', 'courses.json');
const IMAGE_BASE_URL = config.bot.courseImages;

const EMBED_COLORS = {
  Easy: 0x57F287,
  Hard: 0x5865F2
};

let cachedCourses = null;

export class SpinService {
  /**
   * Loads and caches courses from the JSON data file.
   * @returns {Promise<Array>} Array of course objects
   * @throws {Error} If the file cannot be read or parsed
   */
  async loadCourses() {
    if (cachedCourses !== null) {
      return cachedCourses;
    }

    try {
      const content = await readFile(COURSES_FILE_PATH, 'utf-8');
      cachedCourses = JSON.parse(content);
      return cachedCourses;
    } catch (error) {
      throw new Error(`Failed to load courses from ${COURSES_FILE_PATH}: ${error.message}`);
    }
  }

  /**
   * Filters courses by difficulty. Returns all courses if difficulty is null/undefined.
   * @param {Array} courses - Array of course objects
   * @param {string|null} difficulty - "Easy", "Hard", or null for all
   * @returns {Array} Filtered array of course objects
   */
  filterCourses(courses, difficulty) {
    if (!difficulty) {
      return courses;
    }
    return courses.filter(course => course.difficulty === difficulty);
  }

  /**
   * Selects a random course from the provided array.
   * @param {Array} courses - Non-empty array of course objects
   * @returns {Object} A randomly selected course object
   */
  selectRandom(courses) {
    const index = Math.floor(Math.random() * courses.length);
    return courses[index];
  }

  /**
   * Builds a Discord embed for the selected course.
   * @param {Object} course - Course object with code, name, and difficulty
   * @returns {EmbedBuilder} Discord embed with course details
   */
  buildEmbed(course) {
    const imageUrl = `${IMAGE_BASE_URL}${course.code}_FULL.jpg`;
    const color = EMBED_COLORS[course.difficulty] || 0x99AAB5;
    const diffIcon = course.difficulty === 'Easy' ? '🟢' : '🔵';

    return new EmbedBuilder()
      .setTitle(`${diffIcon} ${course.name} — ${course.difficulty}`)
      .setDescription(`\`${course.code}\``)
      .setColor(color)
      .setImage(imageUrl);
  }
}

/**
 * Clears the cached courses data, forcing a reload on next call.
 */
export function clearCache() {
  cachedCourses = null;
}
